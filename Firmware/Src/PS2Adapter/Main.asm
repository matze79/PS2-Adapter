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
 *  Created: 11.09.2016
 *   Author: Christian Machill
 */ 

 ; Taktfrequenz 
.equ FREQ = 8000000


.equ UseWheelMouse = 0					 
; Wheelmouse funktioniert noch nicht, also besser nicht aktivieren
;	Wenn aktiviert, wird die Wheelmouse vom DOS-Treiber "ctmouse" erkannt. Die Bewegungen der Maus funktionieren auch.
;	Buttonclicks werden aber nicht erkannt, desweiteren ist die Tastatur blockiert. Offensichtlich fehlt mir eine bessere
;	Dokumentation zur Wheelmouse. ^^

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
.equ LED_DDR = DDRB
.equ LED_PORT = PORTB
.equ LED_1 = 1
.equ LED_2 = 2
; Port und Pins des LCD
.equ LCD_Enabled = 0
.equ LCD_SteuerPort = PORTB
.equ LCD_SteuerDDR = DDRB
.equ LCD_DatenPort = PORTB
.equ LCD_DatenDDR = DDRB
.equ LCD_PIN_RS = 0
.equ LCD_PIN_E = 3
.equ LCD_PinDB0 = 4

.org 0x000
; #######################################
; ### Hauptprogramm
; #######################################
Hauptprogramm:
	; Stackpointer initialisieren
	ldi ax, LOW(RAMEND)			
	out SPL, ax
	; LCD Initialisieren
	.if LCD_Enabled==1
		rcall LCD_Initialize		; LCD initialisieren
		rcall LCD_ClrScr			; LCD leeren
		rcall LCD_Home				; Cursor setzen
	.endif
	;
	rcall PS2_SetClockHigh
	rcall PS2_SetDataHigh
	ldi ax, 0
	mov SendIDState, ax
	mov CheckRTSWhileWait, ax
	mov UART_RTS_OldState, ax			; Register intialisieren (Dieses Register nutzen wir später, um eine fallende Flanke am RTS-Pin zu erkennen)

	; ### nach dem Einschalten warten wir etwas (die Maus braucht Zeit um sich selbst zu initialisieren)
	ldi dx, 100
WLT1:
	ldi ax, Wait_10ms
	rcall WaitMS
	ldi ax, Wait_10ms
	rcall WaitMS
	dec dx
	brne WLT1
	; ### Maus Initialisieren
	rcall PS2_Init						; OK, Versuchen wir die PS2-Maus zu initialisieren
	brcc PS2MouseOK						; Sprung, wenn erfolgreich
	rjmp MouseInitError					; ansonsten zur Fehlerroutine
PS2MouseOK:
	rcall LED2_On						; LED2 anschalten, um zu signalisieren, das die PS2-Maus erkannt wurde
	; ### auf Wheel-Mouse testen
	ldi MouseType, MouseType_Logitech	; Variable für Maustyp initialisieren (als Standardtyp nehmen wir die Logitech-Maus, da ihr Protokoll 3 Button's unterstützt)
	.if UseWheelMouse==1
		rcall PS2_CheckWheelMouse			; Prüfen, ob die Maus ein Scrollrad hat (die DeviceID wird neu ermittelt)
		brcs NoWheelMouse					; Sprung wenn nicht
		tst ax								; in ax ist die DeviceID, ist die DeviceID > 0 ?
		breq NoWheelMouse					; Sprung wenn nicht
		ldi MouseType, MouseType_MicrosoftWheelMouse	; OK, es ist eine Wheelmaus, dann nutzen wir als Maustyp die MS-Wheelmaus
		rjmp UInit
NoWheelMouse:
	.endif
	; ### UART initialisieren
UInit:
	rcall UART_Init
	ldi ax, 0x00
	mov OldMouseButtonState, ax			; Dieses Register nutzen wir später, um zu erkennen, ob sich die gedrückten Tasten geändert haben
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
	rcall PS2_CalcPS2Mousedata			; aus den Datenbytes die Mausdaten berechnen
	; prüfen, ob es Änderungen gibt	
	tst MouseX
	brne PS2ChangesExist				; X-Richtung wurde verändert
	tst MouseY
	brne PS2ChangesExist				; Y-Richtung wurde verändert
	tst MouseButtonState
	brne PS2ChangesExist				; Mousebutton wurde verändert
	tst OldMouseButtonState
	brne PS2ChangesExist				; Mousebutton wurde verändert
	cpi MouseType, MouseType_MicrosoftWheelMouse	; auf Wheelmaus testen
	brne NoPS2ChangesExist				; wenn keine Wheelmaus, dann abbruch
	tst MouseZ						
	brne PS2ChangesExist				; Scrollrad wurde bewegt
	rjmp NoPS2ChangesExist				; wenn es keine Änderuneg gab, dann Spung 
	; ### Die Maus wurde bewegt, oder ein Button wurde gedrückt 
PS2ChangesExist:
	rcall CheckHotkeys					; auf Hotkeys prüfen
	brcs Main_AfterPS2Read				; Sprung, wenn ein Hotkey benutzt wurde
	; ### Es gab eine Mausbewegung oder einen Mausclick
	rcall LED1_On
	rcall UART_SendMouseData			; Datenpacket umwandeln und über serielle Schnittstelle senden
	.if LCD_Enabled==1
		rcall LCD_ClrScr			; LCD leeren
		rcall LCD_Home				; Cursor setzen
		mov ax, PS2_DataByte1
		rcall LCD_PrintRegisterHEX
		mov ax, PS2_DataByte2
		rcall LCD_PrintRegisterHEX
		mov ax, PS2_DataByte3
		rcall LCD_PrintRegisterHEX
		cpi MouseType, MouseType_MicrosoftWheelMouse
		brne USMD1
		mov ax, MouseZ
		rcall LCD_PrintRegisterHEX
USMD1:
		ldi ax, ' '
		rcall LCD_PrintChar
		mov ax, MouseButtonState
		rcall LCD_PrintRegisterHEX
		mov ax, MouseX
		rcall LCD_PrintRegisterHEX
		mov ax, MouseY
		rcall LCD_PrintRegisterHEX
	.endif

NoPS2ChangesExist:
	mov OldMouseButtonState, MouseButtonState	; den ButtonStatus merken
	mov OldMouseZ, MouseZ						; den Wheel-Wert merken

Main_AfterPS2Read:
	; ### prüfen, ob Zeichen über die Serielle Schnittstelle an uns geschickt wurden, 
	; ### wenn ja, dann einlesen und verwerfen
	rcall UART_ByteAvailable
	brcc GC1
	rcall UART_ReadByte
GC1:
		
	; ### alle Jobs in diesem Schleifendurchlauf abgearbeitet -> von Vorne anfangen
	rjmp MainLoop

; ################################################################################################
; ### Prüfen, ob der Hotkey benutzt wurde, um die Auflösung zu ändern
; ### Hotkey: Linke + Mittlere + Rechte Maustaste gleichzeitig gedrückt
; ################################################################################################
CheckHotkeys:
	mov ax, MouseButtonState				; Buttonstatus nach ax
	cpi ax, 0x07							; wurden alle 3 Tasten gedrückt?
	brne CheckHotkeysEnde					; Nein, dann Sprung 
	rcall PS2_GetStatus						; zuerst ermitteln wir die alte Auflösung
	brcs CheckHotkeysEnde					; Fehler, dann Sprung
	mov ax, PS2_DataByte2					; Statusbyte 2 (alte Auflösung) nach ax
	inc ax									; Auflösung erhöhen (mögliche Werte: 0 - 3)
	sbrc ax, 2								; prüfen, ob Wert<=3 (2. Bit nicht gesetzt), wenn Ja, dann nächsten Befehl überspringen
	ldi ax, 0								; Wenn Wert=4, dann Wert=0 setzen (von vorne anfangen)
	rcall PS2_SetResolution					; und neue Auflösung setzen
	sec
	ret
CheckHotkeysEnde:
	clc
	ret

; ################################################################################################
; ### Wenn die PS2-Maus nicht initialisiert werden konnte, lassen wir eine der LED's blinken
; ################################################################################################
MouseInitError:
	sbi LED_DDR, LED_1					; DDR auf Ausgang schalten
	sbi LED_Port, LED_1					; Pin auf High -> LED aus
	ldi cx, 30							;  \
MIE1:									;   \
	ldi ax, Wait_10ms					;    \  etwas warten
	rcall WaitMS						;    /
	dec cx								;   /
	brne MIE1							;  /
	cbi LED_Port, LED_1					; Pin auf Low -> LED an
	ldi cx, 30							;  \
MIE2:									;   \
	ldi ax, Wait_10ms					;    \  etwas warten
	rcall WaitMS						;    /
	dec cx								;   /
	brne MIE2							;  /
	rjmp MouseInitError					; und von vorne das ganze

; #################################
; ### Schaltet die 1. LED ein
; #################################
LED1_OFF:
	sbi LED_DDR, LED_1					; DDR auf Ausgang schalten
	nop
	nop
	sbi LED_Port, LED_1					; Pin auf High -> LED einschalten
	ret	

; #################################
; ### Schaltet die 1. LED aus
; #################################
LED1_ON:
	sbi LED_DDR, LED_1					; DDR auf Ausgang schalten
	nop
	nop
	cbi LED_Port, LED_1					; Pin auf Low -> LED Ausschalten
	ret	

; #################################
; ### Schaltet die 2. LED ein
; #################################
LED2_OFF:
	sbi LED_DDR, LED_2					; DDR auf Ausgang schalten
	nop
	nop
	sbi LED_Port, LED_2					; Pin auf High -> LED ausschalten
	ret	

; #################################
; ### Schaltet die 2. LED aus
; #################################
LED2_ON:
	sbi LED_DDR, LED_2					; DDR auf Ausgang schalten
	nop
	nop
	cbi LED_Port, LED_2					; Pin auf Low -> LED anschalten
	ret	

; ### Include-Dateien
	.include "Allgemeines.asm"
	.include "ps2.asm"
	.include "UART.asm"
.if LCD_Enabled==1
	.include "LCD.asm"
.endif
