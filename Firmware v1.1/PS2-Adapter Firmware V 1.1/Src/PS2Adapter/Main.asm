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
 * Main.asm
 *
 *  Created Version 1.0 : 11.09.2016
 *   Author: Christian Machill
 *
 *  Updated auf Version 1.1 : 11.02.2018
 *   Author: Christian Machill
 *
 *   Änderungen in Version 1.1
 *	- Unterstützung für Microsoft Wheel Maus
 *	- Das Emulierte Maus-Protokoll ist jetzt unabhängig von der angeschlossenen Maus.
 *	  Es kann also auch eine MS-Wheel Maus emuliert werden, wenn nur eine normale 2-Tasten PS2-Maus 
 *	  ohne Scrollrad angeschlossen ist.
 *  - Das zu emulierende Maus-Protokoll kann jetzt frei konfiguriert werden. Entweder über das Einstellungs-Programm
 *	  aus dem nächsten Punkt, oder über die DIP-Switches auf dem PS2-Adapter, falls vorhanden. 
 *    Der Switch hat dabei die folgenden Einstellmöglichkeiten:
 *		Switch  1		2
 *				OFF		OFF		- automatische Mausauswahl / Einstellung per Software
 *				ON		OFF		- Microsoft 2-Tasten Maus
 *				OFF		ON		- Logitech Maus
 *				ON		ON		- Microsoft Wheel Maus
 *	  
 *	- Optimierung des Programcode's, damit mehr Platz im FLASH-Rom für weitere Funktionen frei wird.
 *	- Die Firmware enthält jetzt einen Settings-Modus, mit dem es möglich ist, über die Serielle 
 *	  Schnittstelle einige Einstellungen für die angeschlossene PS2-Maus und den Mausadapter zu konfigurieren.
 *    Dazu wird das beiliegende DOS-Tool "PS2MASET.EXE" benötigt. Ruft mann dieses Programm ohne Parameter auf, 
 *	  bekommt mann eine kleine Hilfe mit den möglichen Parametern angezeigt. Die Einstellungen werden direkt 
 *	  im EEProm des Adapters gespeichert, müssen also nicht bei jedem Neustart des Rechners wiederholt werden.
 *	  Mit diesen Einstellungen kann mann sowohl den emulierten Maustype festlegen, als auch die Auflösung, Samplerate
 *	  und Skalierung. Des weiteren kann mann sich Informationen zu den aktuellen Einstellungen anzeigen lassen.
 *  - Die Kommunikation des PC's mit dem PS2-Adapter erfolgt nei den meisten Mäusen mit 1200 Baud. Ab jetzt kann 
 *    die Baudrate auf 19200 Baud erhöht werden. Dadurch kann mann ein Problem beheben, das beim Betrieb an 
 *	  einigen KVM-Switches auftritt. Die Maus reagiert dort verzögert. Die Umstellung auf 19200 Baud setzt 
 *    natürlich angepasste Maustreiber auf dem PC vorraus. 
 */ 


 ; Taktfrequenz 
.equ FREQ = 8000000

; Port und Pins der PS2-Maus
.equ PS2_Port = PORTD
.equ PS2_DDR = DDRD
.equ PS2_PIN = PIND
.equ PS2_Clock = 6
.equ PS2_Data = 5
; Port und Pins der Seriellen Schnittstelle
.equ UART_Port = PORTD
.equ UART_DDR = DDRD
.equ UART_Pin = PIND
.equ UART_RTS = 3
; Port und Pins der LED's
.equ LED_On_Ground = 0
.equ LED_DDR = DDRB
.equ LED_PORT = PORTB
.equ LED_1 = 1
.equ LED_2 = 2
; Port und Pins der Switches
.equ Switch_DDR = DDRB
.equ Switch_PIN = PINB
.equ Switch_Port = PORTB
.equ Switch_1 = 3
.equ Switch_2 = 4
; Port und Pins des LCD
.equ LCD_Enabled = 0
.equ LCD_SteuerPort = PORTD
.equ LCD_SteuerDDR = DDRD
.equ LCD_DatenPort = PORTB
.equ LCD_DatenDDR = DDRB
.equ LCD_PIN_RS = 2
.equ LCD_PIN_E = 4
.equ LCD_PinDB0 = 0
.equ LCD_PinDB1 = 5
.equ LCD_PinDB2 = 6
.equ LCD_PinDB3 = 7
;
.equ EEProm_EnableDisable = 0x20	; ab dieser Adresse hinterlegen wir, welche Settings gespeichert wurden
.equ EEProm_Samplerate = 0x00		; Adresse im EEProm für die Einstellung der Samplerate
.equ EEProm_Resolution = 0x01		; Adresse im EEProm für die Einstellung der Resolution
.equ EEProm_Scaling = 0x02			; Adresse im EEProm für die Einstellung der Skalierung
.equ EEProm_MouseType = 0x03		; Adresse im EEProm für die Einstellung des Maustypes
.equ EEProm_Baudrate = 0x04
.org 0x000
	rjmp Hauptprogramm
; #######################################
; ### Hauptprogramm
; #######################################
Hauptprogramm:
	; Stackpointer initialisieren
	ldi ax, LOW(RAMEND)			
	out SPL, ax
	; ##########################################
	; ### Zustand der DIP-Switches ermitteln
	; ##########################################
	cbi Switch_DDR, Switch_1
	cbi Switch_DDR, Switch_2
	nop
	nop
	sbi Switch_Port, Switch_1
	sbi Switch_Port, Switch_2
	nop
	nop
	eor ax, ax
	in bx, Switch_PIN
	sbrs bx, Switch_1
	sbr ax, 1
	sbrs bx, Switch_2
	sbr ax, 2
	mov HardwareSelectedMouse, ax			; 0 = Automatik, 1 = Microsoft Mouse, 2 = Logitech Mouse, 3 = Microsoft Wheel Mouse
	; ##########################################
	; ### ggf. LCD Initialisieren
	; ##########################################
	.if LCD_Enabled==1
		rcall LCD_Initialize		; LCD initialisieren
		rcall LCD_ClrScr			; LCD leeren
		rcall LCD_Home				; Cursor setzen
	.endif
	; ##########################################
	; ### Set PS2-Clock Pin High
	; ##########################################
	sbi PS2_Port, PS2_Clock
	cbi PS2_DDR, PS2_Clock
	; Set PS2-Data Pin High
	sbi PS2_Port, PS2_Data
	cbi PS2_DDR, PS2_Data
	;
	eor ax, ax
	mov SettingMode, ax
	mov CheckRTSWhileWait, ax
	mov UART_RTS_OldState, ax			; Register intialisieren (Dieses Register nutzen wir später, um eine fallende Flanke am RTS-Pin zu erkennen)
	; ### nach dem Einschalten warten wir etwas (die Maus braucht Zeit um sich selbst zu initialisieren)
	ldi dx, 200
WLT1:
	ldi ax, Wait_10ms
	rcall WaitMS
	dec dx
	brne WLT1
	; ##################################
	; ### PS2-Maus Initialisieren
	; ##################################
	rcall PS2_Init							; OK, Versuchen wir die PS2-Maus zu initialisieren
	rcall LED2_On							; LED2 anschalten, um zu signalisieren, das die PS2-Maus erkannt wurde
	; ### auf Wheel-Mouse testen
	ldi PS2_MouseType, MouseType_Logitech	; Variable für Maustyp initialisieren (als Standardtyp nehmen wir die Logitech-Maus, da ihr Protokoll 3 Button's unterstützt)
	rcall PS2_CheckWheelMouse			; Prüfen, ob die Maus ein Scrollrad hat (die DeviceID wird neu ermittelt)
	brcs SerMouseInit					; Sprung wenn nicht
	tst ax								; in ax ist die DeviceID, ist die DeviceID > 0 ?
	breq SerMouseInit					; Sprung wenn nicht
	ldi PS2_MouseType, MouseType_MicrosoftWheelMouse	; OK, es ist eine Wheelmaus, dann nutzen wir als Maustyp die MS-Wheelmaus
	rjmp SerMouseInit
	; ##################################
	; ### Type der Seriellen Maus ermitteln
	; ##################################
SerMouseInit:
	cpi HardwareSelectedMouse, MouseType_Automatik	; ist der Maustyp über die Switches ausgewählt ?
	breq SMI1										; Nein, dann Sprung
	mov SER_Mousetype, HardwareSelectedMouse		; Ja, also Maustype anhand der Switches setzen
	rjmp UInit
SMI1:
	ldi ZL, EEProm_MouseType						; Prüfen, ob für den Maustyp eine Einstellung vorhanden ist
	rcall EE_ReadSetting
	brcs SMI2										; Nein, dann Sprung
	cpi ax, MouseType_Automatik						; Wenn in den Einstellungen Automatik steht, dann weiter prüfen
	breq SMI2				
	mov SER_Mousetype, ax							; ansonsten den Maustyp aus den Einstellungen setzen
	rjmp PS_SetSettings
SMI2:					
	mov SER_Mousetype, PS2_Mousetype				; Einfach den selben Maustyp setzen, wie PS2
	; ##############################################################
	; ### Einstellugen der PS2-Maus aus dem EEProm laden und nutzen
	; ##############################################################
PS_SetSettings:
	ldi ZL, EEProm_Samplerate						
	rcall EE_ReadSetting							; Samplerate lesen
	brcs PSS1										; Sprung, wenn keine Einstellung vorhanden
	rcall PS2_SetSampleRate							; ansonsten die Samplerate setzen
PSS1:
	ldi ZL, EEProm_Resolution						
	rcall EE_ReadSetting							; Resolution lesen
	brcs PSS2										; Sprung, wenn keine Einstellung vorhanden
	rcall PS2_SetResolution							; ansonsten die Resolution setzen
PSS2:
	ldi ZL, EEProm_Scaling						
	rcall EE_ReadSetting							; Scaling lesen
	brcs UInit										; Sprung, wenn keine Einstellung vorhanden
	cpi ax, 1
	breq PSS3
	rcall PS2_Set_SetScaling11						; Scaling 1zu1 setzen
	rjmp UInit
PSS3:
	rcall PS2_Set_SetScaling21						; Scaling 2zu1 setzen
	; ### UART initialisieren
UInit:
	eor Baudrate, Baudrate
	ldi ZL, EEProm_Baudrate						
	rcall EE_ReadSetting							; Baudrate einlesen
	brcs UInit1
	mov Baudrate, ax
UInit1:
	rcall UART_Init									; UART initialisieren
	rcall PS2_EnableDataReporting		; Data-Reporting der Maus aktivieren. Die Maus sendet sonst keine Bewegungsdaten
	ldi ax, 0xFF
	mov CheckRTSWhileWait, ax
	; ##################################################
	; ### ab hier beginnt unsere Hauptschleife
	; ##################################################
MainLoop:	
	rcall LED1_Off
	cbi UART_DDR, UART_RTS
	rcall PS2_GetMouseDatenpaket		; Mausdaten von der PS2-Maus ermitteln
	brcs Main_AfterPS2Read				; Fehler -> dann Sprung
	rcall LED1_On
	rcall UART_SendMouseData			; Datenpacket umwandeln und über serielle Schnittstelle senden
Main_AfterPS2Read:
	; ### prüfen, ob Zeichen über die Serielle Schnittstelle an uns geschickt wurden, 
	; ### wenn ja, dann einlesen. Ist es ein großes S, dann in den Settingsmode springen
	rcall UART_ByteAvailable
	brcc GC1
	rcall UART_ReadByte
	cpi ax, 'S'
	brne GC1
	ldi ax, 'O'
	rcall UART_WriteByte
	rcall SettingsMode
GC1:
	; ### alle Jobs in diesem Schleifendurchlauf abgearbeitet -> von Vorne anfangen
	rjmp MainLoop

; ################################################################################################
; ### Settingsmode - Es werden über die Serielle Schnittstelle Commandos empfangen, und ausgeführt
; ### Commandos: 
; ###	Q = Quit Settingsmode 
; ###	B = Set Baudrate	
; ###		    IN: 0 = 1200 Baud, 1 = 19200 Baud
; ###			OUT: 'O' = OK or 'E' = Error
; ###	R = Set Resolution	
; ###		    IN: 0 = 1count/mm, 1 = 2count/mm, 2=4count/mm, 3=8count/mm
; ###			OUT: 'O' = OK or 'E' = Error
; ###	C = Set Scalling	
; ###			IN: 0 = 1 zu 1, 1 = 2 zu 1
; ###			OUT: 'O' = OK or 'E' = Error
; ###	S = Set Samplerate	
; ###			IN: Samplerate div 2 (Beispiel: für Samplerate 200 muss eine 100 übergeben werden)
; ###			OUT: 'O' = OK or 'E' = Error
; ###	M = Set Mousetype	(nur wenn Mousetype-Selection über die DIP-Switches auf AUTOMATIK steht)
; ###			IN: 0 = Automatik, 1 = Microsoft-Maus, 2 = Logitech-Maus, 3 = Microsoft-Wheelmouse
; ###	G = Get Status		
; ###			OUT: 'O' = OK or 'E' = Error
; ###				Wenn 'O' dann weitere 9 Byte
; ###					6 Byte PS2-Status (je Byte für ein Nibble des PS2-Status, erst das HIGH-Nibble, dann das LOW-Nibble)
; ###					1 Byte aktueller emulierter Mousetype
; ###					1 Byte per Hardware-Switches gesetzter Maustyp
; ###					1 Byte für die Baudrate (0 = 1200 Baud, 1 = 19200 Baud)
; ###			  or 'E' = Error
; ###		Byte 1 von PS2-Status: 
; ###			Bit 0 = Rechte Maus-Taste gedrückt
; ###			Bit 1 = Mittlere Maus-Taste gedrückt
; ###			Bit 2 = Linke Maus-Taste gedrückt
; ###			Bit 3 = immer Null
; ###			Bit 4 = 0 = Scaling 1 zu 1,  1 = Scaling 2 zu 1
; ###			Bit 5 = 0 = Datareporting Disable, 1 = Datareporting Enable
; ###			Bit 6 = 0 = Streammode, 1 = Remotemode
; ###			Bit 7 =	immer Null
; ###		Byte 2 von PS2-Status: Resolution  0 = 1 count/mm, 1 = 2 count/mm, 2 = 4 count/mm, 3 = 8 count/mm
; ###		Byte 3 von PS2-Status: Samplerate (10, 20, 40, 60, 80, 100, 200 ...)
; ################################################################################################
SettingsMode:
	ldi SettingMode, 0xFF				
	eor ax, ax
	mov CheckRTSWhileWait, ax			; Fallende Flanken am RTS-Pin ignorieren
	rcall PS2_DisableDataReporting		; Datareporting abschalten
SettingsMode_MainLoop:
	rcall UART_ReadByte					; auf das Befehlsbyte warten
	cpi ax, 'Q'							; Q = Quit Settingsmode
	breq SettingsMode_Quit
	cpi ax, 'R'							; R = Set Resolution
	brne S1
	rjmp SM_SetResolution
S1: cpi ax, 'C'							; C = Set Scalling
	brne S2
	rjmp SM_SetScaling
S2: cpi ax, 'S'							; S = Set Samplerate
	brne S3
	rjmp SM_SetSampleRate
S3: cpi ax, 'G'							; G = Get PS2-Status
	brne S4
	rjmp SM_GetInfo
	rjmp SM_SetSampleRate
S4: cpi ax, 'M'							; M = Maustype
	brne S5
	rjmp SM_SetMouseType				; Baudrate
S5: cpi ax, 'B'
	brne S6
	rjmp SM_SetBaudrate
S6:
	.if LCD_Enabled==1
		rcall LCD_PrintRegisterHex
	.endif	
	ldi ax, 'E'
	rcall UART_WriteByte
	rjmp SettingsMode_MainLoop
SettingsMode_Quit:
	rcall PS2_EnableDataReporting		; Datareporting wieder aktivieren
	ldi ax, 0xFF
	mov CheckRTSWhileWait, ax
	ldi SettingMode, 0x00
	ret

SM_SetBaudrate:
	rcall UART_ReadByte					; gewünschte Baudrate über Serial einlesen
	mov Baudrate, ax					; neue Baudrate sichern
	ldi ZL, EEProm_Baudrate				; Den Wert im EEProm sichern
	rcall EE_SaveSetting
	ldi ax, 'O'							; ein OK zurück geben
	rcall UART_WriteByte
SMSB1:
	sbis UCSRA, UDRE					; wenn UDRE=1 (Sendebuffer is leer, bereit für neue Daten) dann Sprung
	rjmp SMSB1							; Warten, bis vorherige Übertragung abgeschlossen ist
	ldi ax, Wait_10ms					; nochmal etwas warten
	rcall WaitMS
	ldi ax, Wait_10ms					; nochmal etwas warten
	rcall WaitMS
	rcall UART_INIT						; UART neu initialisieren
	rjmp SettingsMode_Quit
SM_SetMouseType:
	rcall UART_ReadByte					; gewünschten Maustype über Serial einlesen
	ldi ZL, EEProm_MouseType			; Den Wert im EEProm sichern
	rcall EE_SaveSetting
	clc
	rcall SM_SendStatus					; Status zurückgeben
	rjmp SettingsMode_MainLoop

SM_SetResolution:
	rcall UART_ReadByte					; gewünschte Auflösung über Serial einlesen
	push ax								; Auflösung sichern
	rcall PS2_SetResolution				; Auflösung setzen
	pop ax								; Auflösung wieder herstellen
	brcs Q3								; wenn Setzen nicht erfolgreich war, dann gleich den Status senden
	ldi ZL, EEProm_Resolution			; Den Wert im EEProm sichern
	rcall EE_SaveSetting
Q3:	rcall SM_SendStatus					; Status zurückgeben
	rjmp SettingsMode_MainLoop

SM_SetScaling:
	rcall UART_ReadByte					; gewünschte Scallierung über Serial einlesen
	push ax								; Scaling sichern
	cpi ax, 0x01						; Wenn 1 (also Scallung 2zu1) dann Sprung
	breq SSC1
	ldi ax, PS2_Command_SetScaling11	
	rjmp SSC2
SSC1:
	ldi ax, PS2_Command_SetScaling21
SSC2:
	rcall PS2_SendCommand				; Scaling Setzen
	pop ax								; Scaling wieder herstellen
	brcs Q2								; wenn Setzen nicht erfolgreich war, dann gleich den Status senden
	ldi ZL, EEProm_Scaling				; Den Wert im EEProm sichern
	rcall EE_SaveSetting
Q2:	rcall SM_SendStatus
	rjmp SettingsMode_MainLoop

SM_SetSampleRate:
	rcall UART_ReadByte					; gewünschte Samplerate über Serial einlesen
	lsl ax								; ax*2
	push ax								; Samplerate sichern
	rcall PS2_SetSampleRate				; Samplerate setzen
	pop ax								; Samplerate wiederherstellen
	brcs Q1								; wenn Setzen nicht erfolgreich war, dann gleich den Status senden
	ldi ZL, EEProm_Samplerate			; Den Wert im EEProm sichern
	rcall EE_SaveSetting
Q1:	rcall SM_SendStatus
	rjmp SettingsMode_MainLoop

SM_GetInfo:
	rcall PS2_GetStatus
	brcs GI1
	ldi ax, 'O'
	rcall UART_WriteByte
	mov ax, MouseX
	rcall SendByte2UART
	mov ax, MouseY
	rcall SendByte2UART
	mov ax, MouseZ
	rcall SendByte2UART
	mov ax, SER_Mousetype
	rcall UART_WriteByte
	mov ax, HardwareSelectedMouse
	rcall UART_WriteByte
	mov ax, Baudrate
	rcall UART_WriteByte
	rjmp SettingsMode_MainLoop
GI1:
	ldi ax, 'E'
	rcall UART_WriteByte
	rjmp SettingsMode_MainLoop

; sendet das High und das Low-Nibble von ax als zwei Bytes an den UART (das Serielle Protokoll nutzt nur 7 Bytes, daher übertragen wir die 8 Bytes als zwei 7-Bit pakete)
SendByte2UART:
	push ax
	swap ax
	andi ax, 0x0F
	rcall UART_WriteByte
	pop ax
	andi ax, 0x0F
	rcall UART_WriteByte
	ret

SM_SendStatus:
		push ax
		brcc SMSS1
		ldi ax, 'E'
		brcs SMSS2
SMSS1:	ldi ax, 'O'
SMSS2:	rcall UART_WriteByte
		pop ax
		ret


; ################################################################################################
; ### Schreibt einen Einstellung in das EEPROM 
; ### IN:	ZL = Adresse
; ### OUT:	AX = Wert
; ################################################################################################
EE_SaveSetting:
	push ax
	rcall EE_WriteByte					
	adiw ZH:ZL, EEProm_EnableDisable
	ldi ax, 1
	rcall EE_WriteByte					
	pop ax
	ret

; ################################################################################################
; ### Liest einen Einstellung aus dem EEPROM 
; ### IN:	ZL = Adresse
; ### OUT:	Carry = 1 wenn keine Wert gesetzt, ansonsten 0
; ###       AX = Wert, wenn Carry = 0
; ################################################################################################
EE_ReadSetting:
	push ZL
	adiw ZH:ZL, EEProm_EnableDisable
	rcall EE_ReadByte
	POP ZL
	cpi ax, 1
	brne ER2
	rcall EE_ReadByte
	clc
ER1:ret
ER2:sec
	ret
; ################################################################################################
; ### Liest einen Wert aus dem EEPROM 
; ### IN:	ZL = Adresse
; ### OUT:	AX = Wert
; ################################################################################################
EE_ReadByte:
    sbic    EECR,EEWE			; prüfe ob der vorherige Schreibzugriff beendet ist
    rjmp    EE_ReadByte			; wenn nicht dann weiter warten
    out     EEARL, ZL    
    sbi     EECR, EERE			; Lesevorgang aktivieren
    in      ax, EEDR			; Wert nach AX lesen
	ret

; ################################################################################################
; ### Speicher den Wert im EEPROM ab. 
; ### IN: AX = Wert
; ###	  ZL = Adresse
; ################################################################################################
EE_WriteByte:
	push ax						; Wert sichern
EB1:sbic    EECR, EEWE          ; prüfe ob der letzte Schreibvorgang beendet ist
    rjmp    EB1			        ; wenn nicht dann weiter warten
    out     EEARL, ZL           ; 
    out     EEDR, ax            ; zu schreibendes Byte setzen
	in		ax, sreg			; FLAGS sichern
	cli							; vorsichtshalber IRQ's sperren
    sbi     EECR,EEMWE          ; Schreiben vorbereiten
    sbi     EECR,EEWE           ; Und los !
	out		sreg, ax			; FLAGS wiederherstellen und damit IRQ's wieder zulassen
	pop ax						; Wert wiederherstellen
	ret

; #################################
; ### Schaltet die 1. LED aus
; #################################
LED1_OFF:
	sbi LED_DDR, LED_1					; DDR auf Ausgang schalten
	nop
	.if LED_On_Ground==1
		cbi LED_Port, LED_1					; Pin auf Low -> LED ausschalten
	.else 
		sbi LED_Port, LED_1					; Pin auf High -> LED ausschalten
	.endif
	ret	

; #################################
; ### Schaltet die 1. LED an
; #################################
LED1_ON:
	sbi LED_DDR, LED_1					; DDR auf Ausgang schalten
	nop
	.if LED_On_Ground==1
		sbi LED_Port, LED_1					; Pin auf High -> LED anschalten
	.else 
		cbi LED_Port, LED_1					; Pin auf Low -> LED anschalten
	.endif
	ret	

; #################################
; ### Schaltet die 2. LED an
; #################################
LED2_ON:
	sbi LED_DDR, LED_2					; DDR auf Ausgang schalten
	nop
	.if LED_On_Ground==1
		sbi LED_Port, LED_2					; Pin auf High -> LED anschalten
	.else 
		cbi LED_Port, LED_2					; Pin auf Low -> LED anschalten
	.endif
	ret	

; ### Include-Dateien
	.include "Allgemeines.asm"
	.include "ps2.asm"
	.include "UART.asm"
.if LCD_Enabled==1
	.include "LCD.asm"
.endif
