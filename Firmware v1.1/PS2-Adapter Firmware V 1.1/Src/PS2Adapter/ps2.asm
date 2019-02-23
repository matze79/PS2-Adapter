/*
 *  Copyright (C) 2016 Christian Machill
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 3 of the License, or
 *  (at your option) any later version.
 *  
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software Foundation,
 *  Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */
 
 /*
 * ps2.asm
 *
 *  Created: 11.09.2016
 *   Author: Christian Machill
 */ 

.equ PS2_Command_Reset = 0xFF
.equ PS2_Command_SetRemoteMode = 0xFF
.equ PS2_Command_SetStreamMode = 0xEA
.equ PS2_Command_SetSampleRate = 0xF3
.equ PS2_Command_SetResolution = 0xE8
.equ PS2_Command_GetDeviceID = 0xF2
.equ PS2_Command_GetStatus = 0xE9
.equ PS2_Command_ReadData = 0xEB
.equ PS2_Command_SetScaling11 = 0xE6
.equ PS2_Command_SetScaling21 = 0xE7
.equ PS2_Command_EnableDataReporting = 0xF4 
.equ PS2_Command_DisableDataReporting = 0xF5 

.MACRO ShortWait
.if ( FREQ > 1000000 )	
	ldi dx, Wait_50us
	rcall Wait
.endif
.ENDMACRO

.MACRO CheckRTS								; Das gehört zwar eigentlich in das Modul "UART.ASM", aber wenn ich es als Macro aufrufen will, muss es hier stehen. Da es sehr Zeitkritisch ist, muss ich es aber als Macro aufrufen.
	cbi UART_DDR, UART_RTS					; RTS-Pin auf Input setzen
	nop
	nop
	in ax, UART_PIN
	andi ax, (1<<UART_RTS)
	brne C1
	tst UART_RTS_OldState					; War RTS vorher auch schon Low ? 
	breq C1									; Ja, dann sprung (nix weiter machen)
	rcall UART_SendMouseIDString
C1:
	mov UART_RTS_OldState, ax
.ENDMACRO

.MACRO CheckUARTIncommingData
	clc
	sbic UCSRA, RXC
	sec
.ENDMACRO

.MACRO PS2_SetDataPinLow
	cbi PS2_Port, PS2_Data
	sbi PS2_DDR, PS2_Data
.ENDMACRO

.MACRO PS2_SetDataPinHigh
	sbi PS2_Port, PS2_Data
	cbi PS2_DDR, PS2_Data
.ENDMACRO

.MACRO PS2_SetClockPinLow
	cbi PS2_Port, PS2_Clock
	sbi PS2_DDR, PS2_Clock
.ENDMACRO

.MACRO PS2_SetClockPinHigh
	sbi PS2_Port, PS2_Clock
	cbi PS2_DDR, PS2_Clock
.ENDMACRO

.MACRO PS2_WaitWhileClockLow
	rcall PS2_Wait_WhileClockLow
.ENDMACRO

PS2_Wait_WhileClockLow:
	sbrs CheckRTSWhileWait, 1
	rjmp L1
L0:	CheckRTS
	CheckUARTIncommingData
	brcS L2
	rcall PS2_GetClock
	breq L0
	rjmp L2
L1: rcall PS2_GetClock
	breq L1
L2:	ret

.MACRO PS2_WaitWhileClockHigh
	rcall PS2_Wait_WhileClockHigh
.ENDMACRO

PS2_Wait_WhileClockHigh:
	sbrs CheckRTSWhileWait, 1
	rjmp L7
L6:	CheckRTS
	CheckUARTIncommingData
	brcS L8
	rcall PS2_GetClock
	brne L6
	rjmp L8
L7: rcall PS2_GetClock
	brne L7
L8: ret

; #######################################################
; ### ermittelt den Status der Clock-Leitung 
; ### OUT: ax = 0  Clock ist Low
; ###      ax <> 0  Clock ist High
; ###  Wichtig, nicht auf 1 prüfen, sondern auf <> 0
; #######################################################
PS2_GetClock:
	cbi PS2_DDR, PS2_Clock
	nop
	nop
.if ( FREQ > 8000000 )	
	nop						; bei einer Taktfrequenz höher als 1MHz etwas länger
	nop						; warten, bevor wir den PIN auslesen
	nop						; Hintergrund: wenn ich nach dem löschen des BITS im DDR-Register
	nop						; sofort den PIN auslesen, hatte ich oft falsche Werte
	nop						; lässt mann sich aber ein paar Cyclen Zeit stimmen die Werte
	nop
	nop
	nop
.endif
	in ax, PS2_PIN						
	andi ax, 1<<PS2_Clock				
	ret									

; #######################################################
; ### ermittelt den Status der DATA-Leitung 
; ### OUT: ax = 0  Data ist Low
; ###      ax <> 0  Data ist High
; ###  Wichtig, nicht auf 1 prüfen, sondern auf <> 0
; #######################################################
PS2_GetData:
	cbi PS2_DDR, PS2_Data
	nop
	nop
.if ( FREQ > 8000000 )	
	nop						; bei einer Taktfrequenz höher als 1MHz etwas länger
	nop						; warten, bevor wir den PIN auslesen
	nop						; Hintergrund: wenn ich nach dem löschen des BITS im DDR-Register
	nop						; sofort den PIN auslesen, hatte ich oft falsche Werte
	nop						; lässt mann sich aber ein paar Cyclen Zeit stimmen die Werte
	nop
	nop
	nop
.endif
	in ax, PS2_PIN
	andi ax, 1<<PS2_Data
	ret

; ##################################################
; ### Sendet das Byte in AX an die Maus
; ##################################################
PS2_WriteByte:
	push bx							; Register sichern
	push cx
	push dx
	push tx
	ldi tx, 1						; TX dient als Bitmaske
	ldi cx, 8						; CX ist unser Schleifenzähler
	mov bx, ax						; zu schreibendes Byte sichern
	rcall PS2_GetParitaet			; Parität berechnen
	mov tx, ax						; Parität in Register sichern
	PS2_SetDataPinHigh				
	PS2_SetClockPinHigh
	ldi dx, Wait_100us
	rcall Wait
	PS2_SetClockPinLow
	ldi dx, Wait_100us
	rcall Wait
	PS2_SetDataPinLow				; Starbit = 0
	ldi dx, Wait_10us				; Kurz warten
	rcall Wait
	PS2_SetClockPinHigh				; Clockleitung frei geben
PW3Bit_1s:
	PS2_WaitWhileClockHigh			; Warten, solange Clock High ist
	mov ax, bx						; gesichertes zu sendendes Byte nach ax
	andi ax, 0x01					; Maskieren
	brne PW3Bit_1a					; wenn 1, dann Sprung
	PS2_SetDataPinLow				; DATA auf LOW setzen
	rjmp PW3Bit_1b
PW3Bit_1a:
	PS2_SetDataPinHigh				; DATA auf HIGH setzen
PW3Bit_1b:							
	PS2_WaitWhileClockLow			; Warten, solange Clock Low ist
	lsr bx							; Bits im Datebyte nach rechts schieben
	dec cx							; Schleifenzähler verringern
	brne PW3Bit_1s					; Sprung, wenn noch nicht fertig
	PS2_WaitWhileClockHigh			; Warten, solange Clock High ist
	mov ax, tx						; Paritätsbit nach ax
	andi ax,1						; wir brauchen immer nur 1 Bit
	brne PW3Bit_2a					; wenn 1, dann Sprung
	PS2_SetDataPinLow				; DATA auf LOW setzen
	rjmp PW3Bit_2b
PW3Bit_2a:
	PS2_SetDataPinHigh				; DATA auf HIGH setzen
PW3Bit_2b:							
	PS2_WaitWhileClockLow			; Warten, solange Clock Low ist
	PS2_WaitWhileClockHigh			; Warten, solange High Low ist
	PS2_SetDataPinHigh				; Stopbit = 1
	ldi dx, Wait_50us				; Kurz warten
	rcall Wait
	PS2_WaitWhileClockHigh			
	ldi bx, 0
	ori bx, (1<<PS2_Data) | (1<<PS2_Clock)
	cbi PS2_DDR, PS2_Data
	cbi PS2_DDR, PS2_Clock
PW3Byte22:
	in ax, PS2_PIN
	and ax, bx
	cp ax, bx
	brne PW3Byte22					; Warten, bis Clock und Data = High
	PS2_SetClockPinLow				; Clock wieder auf Low setzen, damit die Maus keine weiteren Daten sendet
	pop tx							; Register wiederherstellen
	pop dx
	pop cx
	pop bx
	ret

; ##########################################################
; ### Liest ein Byte von der Maus nach AX
; ###   OUT:  Carryflag 
; ###   wenn gesetzt, dann Fehler beim Startbit, Stopbit 
; ###   oder Paritätsbit falsch
; ##########################################################
PS2_ReadByte:
	push bx							; Register sichern
	push cx
	push dx
	push tx

	ldi bx, 0						; BX wird das gelesene Byte aufnehmen
	ldi tx, 1						; TX dient als Bitmaske
	ldi cx, 8						; CX ist unser Schleifenzähler

	PS2_SetClockPinHigh				; Clock freigeben
	PS2_SetDataPinHigh				; Data Freigeben
	ldi dx, Wait_50us				; Kurz warten
	rcall Wait
	PS2_WaitWhileClockHigh			; warten, bis die Maus Clock auf Low setzt
	brcc PR2Byte0
	rjmp PRByteEnde
PR2Byte0:
	mov dx, ax						; Startbit erstmal nach dx sichern
	PS2_WaitWhileClockLow
	tst dx							; Startbit auf 0 prüfen (muss immer 0 sein)
	breq PR2Byte1					; wenn 0, dann Sprung
	sec								; Carryflag setzen
	rjmp PRByteEnde					; und Procedure beenden
	; ### Datenbits
PR2Byte1:	
	PS2_WaitWhileClockHigh			; Warten solange Clock High ist
	rcall PS2_GetData				; Datenbit einlesen
	tst ax							; prüfen, ob das BIT=HIGH ist
	breq PR2Byte2					; wenn null. dann Sprung
	or bx, tx						; Bit in BX setzen
PR2Byte2:	
	lsl tx							; unsere Bitmaske um eine Stelle nach links schieben
	PS2_WaitWhileClockLow			; und warten, bis Clock wieder HIGH ist
	dec cx							; Schleifenzähler verringern
	brne PR2Byte1					; wenn noch nocht alle BITS gelesen, dann weitere Datenbits einlesen
	PS2_WaitWhileClockHigh			; eat Parity
	rcall PS2_GetData				; Datenbit einlesen
	ldi dx, 0						; DX initialisieren, in DX legen wir erstmal das Paritätsbit ab, und werten es später aus
	sbrc ax, PS2_Data				; wenn Paritätsbit nicht gesetzt, dann nächsten Befehl überspringen
	inc dx							; DX auf 1 setzen (DX enthält jetzt das Paritätsbit an der Position 0)
	PS2_WaitWhileClockLow			; und warten, bis Clock wieder HIGH ist
	PS2_WaitWhileClockHigh			; ; und warten, bis Clock wieder Low ist
	rcall PS2_GetData				; Stopbit einlesen
	mov tx, ax						; und nach tx sichern (tx diente uns bisher als Bitmaske, da tx zu diesem Zeitpunkt nicht mehr benötigt wird, können wir es jetzt anderweitig benutzen)
	PS2_WaitWhileClockLow
	tst tx							; jetzt prüfen wir das Stopbit
	brne PRByte3					; wenn Stopbit=1, dann Sprung (Stopbit muss immer 1 sein)
	sec								; Carryflag setzen
	rjmp PRByteEnde					; und Procedure beenden
PRByte3:	
	mov ax, bx						; Datenbyte nach ax kopieren
	rcall PS2_GetParitaet			; Parität berechnen
	cp ax, dx						; und das berechnete Paritätsbit mit dem empfangenen Paritätsbit vergleichen
	breq PRByte4					; wenn es gleich ist, dann Sprung
	sec								; Carryflag setzen
	rjmp PRByteEnde					; und Procedure beenden
PRByte4:
	mov ax, bx
	clc
PRByteEnde:
	PS2_SetClockPinLow				; Clock wieder auf LOW -> Damit sendet die Maus nicht mehr, bis wir Clock wieder freigeben
	pop tx							; Register wiederherstellen
	pop dx
	pop cx
	pop bx
	ret

; ##########################################################
; ### Ermittelt das Paritätsbit eines Bytes
; ###   IN: AX = Datenbyte
; ###  OUT: AX = 1 Bit = Paritätsbit 
; ##########################################################
PS2_GetParitaet:
	push bx
	mov bx, ax					
	swap ax						
	eor ax, bx					
	mov bx, ax					
	lsr ax						
	lsr ax						
	eor ax, bx					
	mov bx, ax					
	lsr ax						
	eor ax, bx					
	andi ax, 1					
	ldi bx, 1
	eor ax, bx
	pop bx
	ret

PS2_SendCommand:
	rcall PS2_WriteByte					; Befehl senden
	ShortWait
	rcall PS2_ReadByte					; Antwort einlesen
	brcs SC1							; wenn Fehler dann beenden
	cpi ax, 0xFA						; wenn 0xFA dann weiter
	brne SC1							; sonst mit Fehler beenden
	clc
	brcc SC2
SC1:sec
SC2:ret

; ##########################################################
; ### Initialisiert die PS2-Maus
; ##########################################################
PS2_Init:
	; ### Send Reset
	ldi ax, PS2_Command_Reset			
	rcall PS2_WriteByte					; Reset-Befehl senden
	rcall PS2_ReadByte					; ACK lesen - ich prüfe ACK nicht auf den richtigen Wert, weil bei meinen Test's ein KVM-Switsch nach dem Einschalten hier 0x00 gesendet hat, alle Bytes danach waren so wie erwartet
	brcs PS2_Init_Error
	rcall PS2_ReadByte					; BAT-Ergebniss lesen 
	brcs PS2_Init_Error					; wenn Fehler dann beenden
	cpi ax, 0xAA						;
	brne PS2_Init_Error
	rcall PS2_ReadByte					; DeviceID lesen
	brcs PS2_Init_Error					; wenn Fehler dann beenden
	; ### Set Stream Mode
	ldi ax, PS2_Command_SetStreamMode; PS2_Command_SetRemoteMode
	rcall PS2_WriteByte					; auf den REMOTE-MNode umstellen
	rcall PS2_ReadByte					; Antwort einlesen
	brcs PS2_Init_Error					; wenn Fehler dann beenden
	cpi ax, 0xFA						; Antwort OK?
	brne PS2_Init_Error					; wenn nein, dann mit Fehler beenden
	; ### Variablen Initialisieren
	eor ax, ax
	mov MouseButtonState, ax			; \
	mov MouseX, ax						;  \ 
	mov MouseY, ax						;   | Mausvariablen initialisieren
	mov MouseZ, ax						;  /
;	mov OldMouseButtonState, ax			; /
	clc
	ret
PS2_Init_Error:
	sec
	ret

; ##########################################################
; ### Aktiviert das Senden der Datenpakete durch die Maus
; ##########################################################
PS2_EnableDataReporting:
	ldi ax, PS2_Command_EnableDataReporting
	rcall PS2_SendCommand
	ret

; ##########################################################
; ### Deaktiviert das Senden der Datenpakete durch die Maus
; ##########################################################
PS2_DisableDataReporting:
	ldi ax, PS2_Command_DisableDataReporting
	rcall PS2_SendCommand
	ret

; ##########################################################
; ### Setzt die in ax übergebene Auflösung
; ##########################################################
PS2_SetResolution:
	push bx
	mov bx, ax							; Resolution sichern
	ldi ax, PS2_Command_SetResolution
	rcall PS2_SendCommand
	brcs PS2_SetResolution_Error		; wenn Fehler dann beenden
	mov ax, bx							; Resolution wieder herstellen
	rcall PS2_SendCommand
PS2_SetResolution_Error:
	pop bx
	ret
	
; ##########################################################
; ### Setzt Mausscallierung auf 1 zu 1 Modus
; ##########################################################
PS2_Set_SetScaling11:
	ldi ax, PS2_Command_SetScaling11		
	.if LCD_Enabled==1
		rcall LCD_PrintRegisterHEX
	.endif
	rcall PS2_SendCommand
	ret

; ##########################################################
; ### Setzt Mausscallierung auf 2 zu 1 Modus
; ##########################################################
PS2_Set_SetScaling21:
	ldi ax, PS2_Command_SetScaling21		
	.if LCD_Enabled==1
		rcall LCD_PrintRegisterHEX
	.endif
	rcall PS2_SendCommand
	ret

; ##############################################################
; ### Ermittelt den Status der Maus, und legt den Status
; ### in den Registern 'PS2_DataByte1' bis 'PS2_DataByte3' ab
; ##############################################################
PS2_GetStatus:
	ldi ax, PS2_Command_GetStatus		
	rcall PS2_SendCommand
	brcs PS2_GetStatus_Error			; wenn Fehler dann beenden
	rcall PS2_ReadByte					; Datenbyte 1 einlesen
	brcs PS2_GetStatus_Error			; wenn Fehler dann beenden
	mov MouseX, ax						; Datenbyte in MouseX ablegen
	rcall PS2_ReadByte					; Datenbyte 2 einlesen
	brcs PS2_GetStatus_Error			; wenn Fehler dann beenden
	mov MouseY, ax						; Datenbyte in MouseY ablegen
	rcall PS2_ReadByte					; Datenbyte 3 einlesen
	brcs PS2_GetStatus_Error			; wenn Fehler dann beenden
	mov MouseZ, ax						; Datenbyte in MouseZ ablegen
PS2_GetStatus_Error:
	ret

; ##########################################################
; ### Setzt die in ax übergebene Samplerate
; ##########################################################
PS2_SetSampleRate:
	push bx
	push cx
	mov bx, ax							; Samplerate sichern
	ldi ax, PS2_Command_SetSampleRate
	rcall PS2_SendCommand
	brcs PS2_SetSampleRate_Error		; wenn Fehler dann beenden
	mov ax, bx							; Samplerate wieder herstellen
	rcall PS2_SendCommand
PS2_SetSampleRate_Error:
	pop cx
	pop bx
	ret

; ##########################################################
; ### überprüft, ob die PS2-Maus ein Scrollrad hat und
; ### liefert im Erfolgsfall die DeviceID in ax zurück
; ##########################################################
PS2_CheckWheelMouse:
	push cx
	ldi cx, 3							; Schleifenzähler laden
	ldi ZL, LOW(SampleRateArray1*2)		; Adresse mit dem Array der Sampleraten in den Z-Pointer
	ldi ZH, HIGH(SampleRateArray1*2)
PCWM1:
	lpm ax, Z+							; Sampleraten aus Array nach ax
	rcall PS2_SetSampleRate				; Samplerate setzen
	brcs PS2_CheckWheelMouse_Error		; wenn Fehler dann beenden
	dec cx								; Schleifenzähler verringern
	brne PCWM1							; wenn noch nicht fertig, dann weiter
	ldi ax, PS2_Command_GetDeviceID		; so, jetzt ermitteln wir die DeviceID
	rcall PS2_SendCommand
	brcs PS2_CheckWheelMouse_Error		; wenn Fehler dann beenden
	ShortWait
	rcall PS2_ReadByte					; DeviceID lesen
	brcs PS2_CheckWheelMouse_Error		; wenn Fehler dann beenden
	push ax								; DeviceID sichern
	ldi ax, 100							; zum Schluss setzten wir die Samplerate wieder auf den Standartwert 100
	rcall PS2_SetSampleRate				; Samplerate 100 setzen
	pop ax								; DeviceID wiederherstellen
	pop cx
	clc
	ret
PS2_CheckWheelMouse_Error:
	pop cx
	sec
	ret


; ##########################################################
; ### Berechnet aus den Datenbytes die Mausdaten
; ##########################################################
PS2_GetMouseDatenpaket:
	rcall PS2_ReadByte
	brcs PGMZ2
	;andi ax, 0x07
	mov MouseButtonState, ax
	rcall PS2_ReadByte
	mov MouseX, ax
	rcall PS2_ReadByte
	neg ax
	mov MouseY, ax
	eor MouseZ, MouseZ			; MouseZ auf 0 setzen
	cpi PS2_MouseType, MouseType_MicrosoftWheelMouse  ; Ist es eine Wheelmaus? wenn ja, wird ein weiteres Datenbyte gesendet, welches wir einlesen müssen
	brne PGMZ1									  ; wenn nein, dann Sprung
	rcall PS2_ReadByte
	mov MouseZ, ax
PGMZ1:
	clc
PGMZ2:
	ret

SampleRateArray1:
	.db 200, 100, 80, 0
