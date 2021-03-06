uses crt, dos;

Const
 SER_IRQ_ENABLE   =  $01;                { Interrupt-Enable-Register }
 SER_LINE_CONTROL =  $03;                        { Leitungskontrolle }
 SER_MODEM_CONTROL=  $04;                           { Modemkontrolle }
 SER_LINE_STATUS  =  $05;                           { Leitungsstatus }

Const
 Baud_1200 = 96;
 Baud_19200 = 6;

Const Setting_Scalling = 0;
Const Setting_Resolution = 1;
Const Setting_Samplerate = 2;
Const Setting_MouseType = 3;
Const Setting_Baudrate = 4;

var SettingChangesExists:boolean;
var MustChangeSetting:array[0..4] of boolean;
var ChangeSettingTo:array[0..4] of byte;
var GetInfo:boolean;
var GetHelp:boolean;
var UseComport:integer;
var UseBaudrate:word;

var Old_IRQ:pointer;
var OldIntMask:Byte;
var OldMCR:Byte;

var ReadBuffer:array[0..255] of byte;
var ReadBufferPos:integer;
var Buffer:array[0..255] of byte;
var BWrittenPos:integer;
var BReadPos:integer;
var CP:Integer;
var SettingOK:Boolean;
var StatusByte:byte;
var SValue:Byte;
var ComPortOK:Boolean;
var ComPort:word;
var ComIRQ:Byte;
var i:integer;


{
###########################################################################
# Die Interrupt-Routine, welche die Daten von der Seriellen-Schnittstelle
# entgegen nimmt, und im Puffer ablegt
###########################################################################
}
procedure MyIRQ; interrupt;
var Zeichen:Byte;
begin
     asm
     mov dx, ComPort
     add dx, 2
     in al, dx
     and al, 1
     jnz @MI1
     mov dx, ComPort
     lea si, Buffer
     in al, dx
     mov bx, BWrittenPos
     inc bx
     and bx, $FF
     mov [si+bx], al
     mov BWrittenPos,bx
@MI1:
     mov al, $20
     out $20, al
     end;

end;


{
###########################################################################
# Schliest den COM-Port, und stellt die alte Interrupt-Routine wieder her.
###########################################################################
}
Procedure DoneSerial(pComPort:word; pComIRQ:Byte);
begin;
      SetIntVec($08+pComIRQ,Old_IRQ);
      asm
         mov al, OldIntMask
         out $21, al
         mov al, OldMCR
         mov dx, pComPort
         add dx, SER_MODEM_CONTROL
         out dx, al
      end;
end;

{
###########################################################################
# Sichert die alte Interrupt-Routine, und Intialisert den COM-Port
# pBaud 96 = 1200 Baud, pBaud 06 = 19200 Baud,
###########################################################################
}
Procedure InitSerial(pComPort:word; pComIRQ:Byte; pBaud:Word);
begin;
      GetIntVec($08+pComIRQ,Old_IRQ);
      SetIntVec($08+pComIRQ,addr(MyIRQ));
      asm;
      mov di, pComPort
      { Devisor Latch Bit setzen }
      mov dx, di
      add dx, SER_LINE_CONTROL  { +3 - Serial Line Control}
      in al, dx
      or al, $80
      out dx, al                {DLAB an}
      mov dx, di
      mov ax, pBaud
      out dx, ax                {Baudrate setzen}
      add dx, SER_LINE_CONTROL
      mov ax, $02
      out dx, ax                {DLAB aus, 7N1 setzen}
      mov dx, di
      add dx, SER_LINE_STATUS
      in ax, dx                 {Status BITS l�schen}
      mov dx, di
      in al, dx                 {Lesebuffer leeren}
      mov dx, di
      add dx, SER_IRQ_ENABLE
      mov ax, $0001
      out dx, ax                {Enable int, Disable FIFO}
      mov dx, di
      add dx, SER_MODEM_CONTROL
      in al, dx
      mov OldMCR, al
      mov al, $8
      out dx, al
      mov bh, $F7               {wenn COM2, dann Bitmask F7}
      mov bl, pComIRQ
      cmp bl, 3
      jz @IS1
      mov bh, $EF               {wenn COM1, dann Bitmask EF}
@IS1:
      in al, $21
      mov OldIntMask, al
      and al, bh
      out $21, al               {Enable irq}
      end;
end;

{
###########################################################################
# sendet ein Byte an die Serielle Schnittstelle
###########################################################################
}
function WriteComPort(pComPort: word; Wert:Byte):boolean;
var RetValue:Boolean;
var h, m, s, hund : Word;
var h2, m2, s2, hund2 : Word;
var StartTimer:integer;
var Timeout:integer;
var Ende:Boolean;
begin
    RetValue:=false;
    GetTime(h,m,s,hund);
    StartTimer:=s*100+hund;
    Timeout:=100;
    Ende:=false;
    while Ende=false do begin
      if (port[pComPort+SER_LINE_STATUS] and 32)<>0 then begin
         port[pComPort]:=Wert;
         RetValue:=true;
         Ende:=true;
      end;
      GetTime(h2,m2,s2,hund2);
      if (s2*100+hund2)-StartTimer>Timeout then
         Ende:=true;
    end;
    WriteComPort:=RetValue;
end;

{
###########################################################################
# Liest Daten vom COMPort, bzw. wartet darauf, das die Interrupt-Routine
# Daten liefert
###########################################################################
}

function ReadFromComPort(MaxChar:integer):boolean;
var RetValue:Boolean;
var h, m, s, hund : Word;
var h2, m2, s2, hund2 : Word;
var StartTimer:integer;
var Timeout:integer;
var Ende:Boolean;
begin
    RetValue:=false;
    ReadBufferPos:=0;
    GetTime(h,m,s,hund);
    StartTimer:=s*100+hund;
    Timeout:=100;
    Ende:=false;
    while Ende=false do begin
      while BReadPos<>BWrittenPos do begin
         BReadPos:=BReadPos+1;
         BReadPos:=BReadPos and $FF;
         ReadBufferPos:=ReadBufferPos+1;
         ReadBuffer[ReadBufferPos]:=Buffer[BReadPos];
         if ReadBufferPos=1 then begin
            if ReadBuffer[ReadBufferPos]=ord('E') then
               Ende:=true;
         end;
         if ReadBufferPos>=MaxChar then
            Ende:=true;
         GetTime(h,m,s,hund);
         StartTimer:=s*100+hund;
      end;
      GetTime(h2,m2,s2,hund2);
      if ((s2*100+hund2)-StartTimer>Timeout) or ((s2*100+hund2)<StartTimer) then
      if ((s2*100+hund2)-StartTimer>Timeout) then
         Ende:=true;
    end;
    if ReadBufferPos>0 then RetValue:=true;
    ReadFromComPort:=RetValue;
end;

{
###########################################################################
# wie der Name schon sagt. ^^
###########################################################################
}
procedure PrintHelpScreen;
begin
    writeln('m�gliche Parameter (alle Parameter sind optional)');
    writeln('');
    writeln('  /G    - Liefert Informationen zu den aktuellen Einstellungen');
    writeln('  /P:n  - COM-Port. m�gliche Werte: [1-4]');
    writeln('          wenn der Parameter fehlt, wird der COM-Port automatisch ermittelt.');
    writeln('  /B:n  - Baudrate. m�gliche Werte: [1200 oder 19200]');
    writeln('  /C:n  - setzt die Skallierung. m�gliche Werte: [0-1]');
    writeln('            0 = 1 zu 1 Skallierung oder 1 = 2 zu 1 Skallierung');
    writeln('  /R:n  - setzt die Aufl�sung. m�gliche Werte: [0-3]');
    writeln('            0 = 1 count/mm, 1 = 2 count/mm, 2 = 4 count/mm, 3 = 8 count/mm');
    writeln('  /S:n  - setzt die Samplerate. m�gliche Werte: [10-320]');
    writeln('            �bliche Werte: 10, 20, 40, 60, 80, 100, 200');
    writeln('  /M:n  - setzt den Maustype. m�gliche Werte: [0-3]');
    writeln('            0 = Automatische Auswahl   1 = Microsoft Maus');
    writeln('            2 = Logitech Maus          3 = Microsoft Wheel Maus');
    writeln('            ');
    writeln('        Der Maustype kann nur dann gesetzt werden, wenn keine DIP-Switches auf ');
    writeln('        dem PS2-Mausadapter vorhanden sind, oder die beiden Switches auf OFF ');
    writeln('        stehen. Der neue Maustype wird erst nach einem Neustart des Maus-');
    writeln('        adapters aktiv.');
end;

{
###########################################################################
# �berpr�ft die Comandozeilen Parameter, und wertet Sie aus
###########################################################################
}
function CheckCMDParameters:boolean;
var MyParam:string;
var ErrorMsg:string;
var ValueStr:string;
var Value:integer;
var Code:integer;
var ParamOK:boolean;
var RetValue:boolean;

begin
    RetValue:=true;
    if paramcount<>0 then begin
       { Parameter einlesen }
       for i:=1 to paramcount do begin
           ParamOK:=false;
           MyParam:=ParamStr(i);
           if copy(MyParam,1,1)='/' then begin
              case UpCase(MyParam[2]) of
                'P': begin
                        if copy(MyParam,3,1)=':' then begin
                           ValueStr:=copy(MyParam,4,length(MyParam)-3);
                           val(ValueStr, Value, Code);
                           if Code=0 then begin
                              if (Value=1) or (Value=2) then begin
                                 UseComport:=Value;
                                 ParamOK:=true;
                              end;
                           end;

                        end;
                     end;
                'B': begin
                        if copy(MyParam,3,1)=':' then begin
                           ValueStr:=copy(MyParam,4,length(MyParam)-3);
                           val(ValueStr, Value, Code);
                           if Code=0 then begin
                              if (Value=1200) or (Value=19200) then begin
                                 SettingChangesExists:=true;
                                 MustChangeSetting[Setting_Baudrate]:=true;
                                 if Value=1200 then begin
                                    ChangeSettingTo[Setting_Baudrate]:=0
                                 end else begin
                                    ChangeSettingTo[Setting_Baudrate]:=1;
                                 end;
                                 ParamOK:=true;
                              end;
                           end;

                        end;
                     end;
                'C': begin
                        if copy(MyParam,3,1)=':' then begin
                           ValueStr:=copy(MyParam,4,length(MyParam)-3);
                           val(ValueStr, Value, Code);
                           if Code=0 then begin
                              if (Value=0) or (Value=1) then begin
                                 SettingChangesExists:=true;
                                 MustChangeSetting[Setting_Scalling]:=true;
                                 ChangeSettingTo[Setting_Scalling]:=Value;
                                 ParamOK:=true;
                              end;
                           end;

                        end;
                     end;
                'R': begin
                        if copy(MyParam,3,1)=':' then begin
                           ValueStr:=copy(MyParam,4,length(MyParam)-3);
                           val(ValueStr, Value, Code);
                           if Code=0 then begin
                              if (Value=0) or (Value=1) or (Value=2) or (Value=3) then begin
                                 SettingChangesExists:=true;
                                 MustChangeSetting[Setting_Resolution]:=true;
                                 ChangeSettingTo[Setting_Resolution]:=Value;
                                 ParamOK:=true;
                              end;
                           end;

                        end;
                     end;
                'S': begin
                        if copy(MyParam,3,1)=':' then begin
                           ValueStr:=copy(MyParam,4,length(MyParam)-3);
                           val(ValueStr, Value, Code);
                           if Code=0 then begin
                              if (Value>=10) and (Value<=320) then begin
                                 SettingChangesExists:=true;
                                 MustChangeSetting[Setting_Samplerate]:=true;
                                 ChangeSettingTo[Setting_Samplerate]:=Value;
                                 ParamOK:=true;
                              end;
                           end;

                        end;
                     end;
                'M': begin
                        if copy(MyParam,3,1)=':' then begin
                           ValueStr:=copy(MyParam,4,length(MyParam)-3);
                           val(ValueStr, Value, Code);
                           if Code=0 then begin
                              if (Value=0) or (Value=1) or (Value=2) or (Value=3) then begin
                                 SettingChangesExists:=true;
                                 MustChangeSetting[Setting_MouseType]:=true;
                                 ChangeSettingTo[Setting_MouseType]:=Value;
                                 ParamOK:=true;
                              end;
                           end;

                        end;
                     end;
                'G': begin
                          GetInfo:=true;
                          ParamOK:=true;
                     end;
                '?': begin
                          GetHelp:=true;
                          ParamOK:=true;
                     end;
              end;
           end else begin
               ErrorMsg:='Ung�ltiger Parameter';
           end;
           if ParamOK=false then begin
              writeln('Ung�ltiger Parameter. Benutze /? f�r eine Hilfe.');
              RetValue:=false;
              CheckCMDParameters:=RetValue;
              exit;
           end;
       end;
    end;
    CheckCMDParameters:=RetValue;
end;


{
###########################################################################
# Wertet die Statusinformationen vom PS2-Mausadapter aus
###########################################################################
}
procedure PrintCurrentStatus;
begin;
    case ReadBuffer[10] of
      0: writeln('Baudrate: 1200');
      1: writeln('Baudrate: 19200');
    else

writeln(ReadBuffer[10]);
    end;
    StatusByte:=((ReadBuffer[2] and $0F) shl 4) + (ReadBuffer[3] and $0F);
    if (StatusByte and $10)=$10 then begin
      writeln('Scaling: 2 zu 1');
    end else begin
      writeln('Scaling: 1 zu 1');
    end;
    StatusByte:=((ReadBuffer[4] and $0F) shl 4) + (ReadBuffer[5] and $0F);
    case StatusByte of
      0: writeln('Resolution: 1 count/mm');
      1: writeln('Resolution: 2 count/mm');
      2: writeln('Resolution: 4 count/mm');
      3: writeln('Resolution: 8 count/mm');
    end;
    StatusByte:=((ReadBuffer[6] and $0F) shl 4) + (ReadBuffer[7] and $0F);
    write('Samplerate: ');writeln(StatusByte);
    case ReadBuffer[8] of
      1: writeln('Aktueller benutzer Maustype: Microsoft Maus');
      2: writeln('Aktueller benutzer Maustype: Logitech Maus');
      3: writeln('Aktueller benutzer Maustype: Microsoft Wheel Maus');
    end;
    case ReadBuffer[9] of
      0: writeln('Mausart durch den DIP-Switch: automatische Auswahl oder per Software gesetzt');
      1: writeln('Mausart durch den DIP-Switch: Microsoft Maus');
      2: writeln('Mausart durch den DIP-Switch: Logitech Maus');
      3: writeln('Mausart durch den DIP-Switch: Microsoft Wheel Maus');
    end;
end;


{
###########################################################################
# Zuweisung von Port und IRQ anhand der COM-Nummer
###########################################################################
}
procedure SetIRQPortByNumber(Com:integer);
begin
   case Com of
     1 : begin
           ComPort:=$03F8;
           ComIRQ:=4;
         end;
     2 : begin
           ComPort:=$02F8;
           ComIRQ:=3;
         end;
     3 : begin
           ComPort:=$03E8;
           ComIRQ:=4;
         end;
     4 : begin
           ComPort:=$02E8;
           ComIRQ:=3;
         end;
   end;

end;


{
###########################################################################
# Durchsucht die COM-Ports nach dem PS2-Mausadapter
###########################################################################
}
function SearchPS2Adapter(FromPort:integer; ToPort:integer):integer;
var FoundOnComport:integer;
begin
     FoundOnComport:=0;
     { ComPort suchen - zuerst COM1 }
     writeln('Suche nach PS2-Mausadapter');
     CP:=FromPort-1;
     while (CP<ToPort) and (FoundOnComport=0) do begin
        CP:=CP+1;
        write('Pr�fe COM');write(CP);write(': ');
        SetIRQPortByNumber(CP);
        { suche mit 1200 Baud }
        InitSerial(ComPort, ComIRQ, Baud_1200);
        if WriteComPort(ComPort, ord('S'))=true then begin
           if ReadFromComPort(1)=true then begin
              if ReadBuffer[1]=ord('O') then begin
                 WriteComPort(ComPort, ord('Q'));
                 { PS2-Adapter gefunden }
                 UseBaudrate:=Baud_1200;
                 FoundOnComport:=CP;
                 ComPortOK:=true;
                 writeln(' gefunden');
              end;
           end;
           DoneSerial(ComPort, ComIRQ);
        end;
        if FoundOnComport=0 then begin
           { suche mit 19200 Baud }
           InitSerial(ComPort, ComIRQ, Baud_19200);
           if WriteComPort(ComPort, ord('S'))=true then begin
              if ReadFromComPort(1)=true then begin
                 if ReadBuffer[1]=ord('O') then begin
                    WriteComPort(ComPort, ord('Q'));
                    UseBaudrate:=Baud_19200;
                    FoundOnComport:=CP;
                    ComPortOK:=true;
                    writeln(' gefunden');
                 end;
              end;
              DoneSerial(ComPort, ComIRQ);
           end;
        end;
        if FoundOnComport=0 then begin
           writeln(' nicht gefunden');
        end;
     end;
     SearchPS2Adapter:=FoundOnComport;
end;

{
###########################################################################
# Das Hauptprogramm
###########################################################################
}
begin
    { Variablen Initialisieren }
    SettingChangesExists:=false;
    BWrittenPos:=255;
    BReadPos:=255;
    GetInfo:=false;
    GetHelp:=false;
    UseComport:=0;
    for i:=0 to 3 do begin
       MustChangeSetting[i]:=false;
       ChangeSettingTo[i]:=0;
    end;
    { Commandozeilenparameter auswerten }
    if paramcount<>0 then begin
       if CheckCMDParameters=false then begin
          halt(0);
       end;
    end else begin
       GetHelp:=true;
    end;
    { ggf. Hilfe anzeigen }
    if GetHelp=true then begin;
        PrintHelpScreen;
    end;
    { Setting �ndern }
    if (GetInfo=true) or (SettingChangesExists=true) then begin
        { ComPort initialisieren }
        ComPortOK:=false;
        if UseComport=0 then begin
           UseComport:=SearchPS2Adapter(1, 4);
        end else begin
           UseComport:=SearchPS2Adapter(UseComport, UseComport);
        end;
        if ComPortOK=false then begin
           writeln('Der PS2-Mausadapter konnte nicht gefunden werden.');
           halt(0);
        end;
        InitSerial(ComPort, ComIRQ, UseBaudrate);
        WriteComPort(ComPort, ord('S'));
        { in den Settins-Modus wechseln }
        if ReadFromComPort(1)=true then begin
           if ReadBuffer[1]=ord('O') then begin
              { ggf. Baudrate Setzen }
              if MustChangeSetting[Setting_Baudrate]=true then begin
                 SettingOK:=false;
                 SValue:=ChangeSettingTo[Setting_Baudrate];
                 write('Setze Aufl�sung auf ');
                 case SValue of
                      0 : write('1200 Baud');
                      1 : write('19200 Baud');
                 end;
                 write(': ');
                 WriteComPort(ComPort, ord('B'));
                 WriteComPort(ComPort, SValue);
                 SettingOK:=false;
                 if ReadFromComPort(1)=true then begin
                    if ReadBuffer[1]=ord('O') then begin
                       SettingOK:=true;
                    end;
                 end;
                 if SettingOK=true then begin
                    { neue Baudrate setzen }
                    SettingOK:=false;
                    DoneSerial(ComPort, ComIRQ);
                    if SValue=0 then begin
                       UseBaudrate:=Baud_1200;
                    end else begin
                       UseBaudrate:=Baud_19200;
                    end;
                    delay(200);
                    InitSerial(ComPort, ComIRQ, UseBaudrate);
                    delay(200);
                    WriteComPort(ComPort, ord('S'));
                    if ReadFromComPort(1)=true then begin
                       if ReadBuffer[1]=ord('O') then begin
                          SettingOK:=true;
                       end;
                    end;
                 end;
                 if SettingOK=true then begin
                    writeln('OK');
                 end else begin
                    writeln('Fehler');
                 end;
              end;
              { ggf. Resulution Setzen }
              if MustChangeSetting[Setting_Resolution]=true then begin
                 SettingOK:=false;
                 SValue:=ChangeSettingTo[Setting_Resolution];
                 write('Setze Aufl�sung auf ');
                 case SValue of
                      0 : write('1 count/mm');
                      1 : write('2 count/mm');
                      2 : write('4 count/mm');
                      3 : write('8 count/mm');
                 end;
                 write(': ');
                 WriteComPort(ComPort, ord('R'));
                 WriteComPort(ComPort, SValue);
                 SettingOK:=false;
                 if ReadFromComPort(1)=true then begin
                    if ReadBuffer[1]=ord('O') then begin
                       SettingOK:=true;
                    end;
                 end;
                 if SettingOK=true then begin
                    writeln('OK');
                 end else begin
                    writeln('Fehler');
                 end;
              end;
              { ggf. Scalling Setzen }
              if MustChangeSetting[Setting_Scalling]=true then begin
                 SettingOK:=false;
                 SValue:=ChangeSettingTo[Setting_Scalling];
                 write('Setze Scalierung auf ');
                 case SValue of
                      0 : Write('1 zu 1');
                      1 : Write('2 zu 1');
                 end;
                 write(': ');
                 WriteComPort(ComPort, ord('C'));
                 WriteComPort(ComPort, SValue);
                 SettingOK:=false;
                 if ReadFromComPort(1)=true then begin
                    if ReadBuffer[1]=ord('O') then begin
                       SettingOK:=true;
                    end;
                 end;
                 if SettingOK=true then begin
                    writeln('OK');
                 end else begin
                    writeln('Fehler');
                 end;
              end;
              { ggf. Samplerate setzen }
              if MustChangeSetting[Setting_SampleRate]=true then begin
                 SettingOK:=false;
                 write('Setze Samplerate auf ');
                 write(ChangeSettingTo[Setting_SampleRate]);
                 write(': ');
                 WriteComPort(ComPort, ord('S'));
                 SValue:=ChangeSettingTo[Setting_SampleRate];
                 SValue:=SValue shr 1;
                 WriteComPort(ComPort, SValue);
                 SettingOK:=false;
                 if ReadFromComPort(1)=true then begin
                    if ReadBuffer[1]=ord('O') then begin
                       SettingOK:=true;
                    end;
                 end;
                 if SettingOK=true then begin
                    writeln('OK');
                 end else begin
                    writeln('Fehler');
                 end;
              end;
              { ggf. Maustype setzen }
              if MustChangeSetting[Setting_MouseType]=true then begin
                 SettingOK:=false;
                 SValue:=ChangeSettingTo[Setting_MouseType];
                 write('Setze Maustype auf ');
                 case SValue of
                      0: write('Automatische Auswahl');
                      1: write('Microsoft Maus');
                      2: write('Logitech Maus');
                      3: write('Microsoft Wheel Maus');
                 end;
                 write(': ');
                 WriteComPort(ComPort, ord('M'));
                 WriteComPort(ComPort, SValue);
                 SettingOK:=false;
                 if ReadFromComPort(1)=true then begin
                    if ReadBuffer[1]=ord('O') then begin
                       SettingOK:=true;
                    end;
                 end;
                 if SettingOK=true then begin
                    writeln('OK');
                 end else begin
                    writeln('Fehler');
                 end;
              end;
              { ggf. Info ausgeben }
              if GetInfo=true then begin
                 SettingOK:=false;
                 write('Aktuellen Mausstatus ermitteln: ');
                 WriteComPort(ComPort, ord('G'));
                 if ReadFromComPort(10)=true then begin
                    if ReadBuffer[1]=ord('O') then begin
                       SettingOK:=true;
                    end;
                 end;
                 if SettingOK=true then begin
                    writeln('OK');
                    PrintCurrentStatus;
                 end else begin
                    writeln('Fehler');
                 end;
              end;
              {Setting-Modus verlassen }
              WriteComPort(ComPort, ord('Q'));
           end;
        end;
        DoneSerial(ComPort, ComIRQ);
    end;
end.
