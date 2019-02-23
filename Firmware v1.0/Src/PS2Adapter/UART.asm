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
 * UART.asm
 *
 *  Created: 11.09.2016
 *   Author: Christian Machill
 */ 
.equ BAUD  = 1200                               ; Baudrate
 
; Berechnungen für die Baudrate (gefunden auf http://www.mikrocontroller.net/articles/AVR-Tutorial:_UART)
.equ UBRR_VAL   = ((FREQ+BAUD*8)/(BAUD*16)-1)	; clever runden
.equ BAUD_REAL  = (FREQ/(16*(UBRR_VAL+1)))      ; Reale Baudrate
.equ BAUD_ERROR = ((BAUD_REAL*1000)/BAUD-1000)  ; Fehler in Promille
 
.if ((BAUD_ERROR>10) || (BAUD_ERROR<-10))       ; max. +/-10 Promille Fehler
  .error "Systematischer Fehler der Baudrate grösser 1 Prozent und damit zu hoch!"
.endif

; ######################################################################
; ### Initialisiert die Serielle Schnittstelle 
; ######################################################################
UART_Init:
    ; Baudrate setzen
	ldi ax, HIGH(UBRR_VAL)
    out UBRRH, ax
    ldi ax, LOW(UBRR_VAL)
    out UBRRL, ax
	; Sende und Empfangsparameter setzen (wir brauchen 7N1 )
	ldi ax, (1<<UCSZ1)
	out UCSRC, ax
	sbi UCSRB,TXEN
	sbi UCSRB,RXEN
	ret

; ######################################################################
; ### versenden das Byte bzw. das Zeichen in ax über die 
; ### Serielle Schnittstelle 
; ######################################################################
UART_WriteByte:
UART_WriteByte2:
	sbis UCSRA, UDRE		; wenn UDRE=1 (Sendebuffer is leer, bereit für neue Daten) dann Sprung
	rjmp UART_WriteByte2		; Warten, bis vorherige Übertragung abgeschlossen ist
	out UDR, ax				; zu sendendes Byte in dem Sendebuffer ablegen
	ret

; ######################################################################
; ### empfängt ein Zeichen von der Seriellen Schnittstelle, 
; ### und liefert es in ax zurück 
; ######################################################################
UART_ReadByte:
UART_ReadByte2:
	sbis UCSRA, RXC			; wenn RXC=1 (Empfangsbuffer enthält Daten) dann Sprung
	rjmp UART_ReadByte2		; Warten, bis Daten im Empfangsbuffer verfügbar sind
	in ax, UDR				; Empfangsbuffer nach AX kopieren
	ret

; ######################################################################
; ### prüft, ab ein Byte bzw, Zeichen gelesen werden kann ###
; ###   OUT:	CarryFlag = 0	Keine Zeichen im Empfangsbuffer 
; ###			CarryFlag = 1	Zeichen im Empfangsbuffer verfügbar
; ######################################################################
UART_ByteAvailable:
	clc
	sbic UCSRA, RXC
	sec
	ret

; #######################################################
; ### ermittelt den Status der RTS-Leitung 
; ### OUT: ax = 0  Data ist Low
; ###      ax <> 0  Data ist High
; ###  Wichtig, nicht auf 1 prüfen, sondern auf <> 0
; #######################################################
UART_GetRTS:
	cbi UART_DDR, UART_RTS	; RTS-Oin auf Input setzen
	nop
	nop
.if ( FREQ > 1000000 )	
	nop						; bei einer Taktfrequenz höher als 1MHz etwas länger
	nop						; warten, bevor wir den PIN auslesen
	nop						; Hintergrund: wenn ich nach dem löschen des BITS im DDR-Register
	nop						; sofort den PIN auslesen, hatte ich oft falsche Werte
	nop						; lässt mann sich aber ein paar Cyclen Zeit stimmen die Werte
	nop
.endif
	in ax, UART_PIN
	andi ax, 1<<UART_RTS
	ret

; ######################################################################
; ### Senden den Identifikationsstring über die Serielle Schnittstelle
; ######################################################################
UART_SendMouseIDString:
	push ax
	push cx
	cpi MouseType, MouseType_MicrosoftWheelMouse	; Ist eine Wheelmaus angeschlossen
	breq SetWheelMouseIDString						; wenn Ja, dann Sprung
	ldi ZL, LOW(MouseIDString_Logitech*2)			; Adresse mit ID-String in den Z-Pointer
	ldi ZH, HIGH(MouseIDString_Logitech*2)
	rjmp SendMouseIDString
SetWheelMouseIDString:
	ldi ZL, LOW(MouseIDString_Wheelmouse*2)			; Adresse mit ID-String in den Z-Pointer
	ldi ZH, HIGH(MouseIDString_Wheelmouse*2)
SendMouseIDString:
	lpm cx, Z+										; Anzahl der zu sendenden Bytes in den Schleifenzähler CX
	sub cx, SendIDState
SMIDS1:
	sbis UCSRA, UDRE				; wenn UDRE=1 (Sendebuffer is leer, bereit für neue Daten) dann Sprung
	rjmp SMIDS2						; nicht bereit -> Abbruch, später nochmal versuchen
	lpm ax, Z+										; Byte nach AX
	rcall UART_WriteByte							; und Byte ausgeben
	inc SendIDState
	dec cx											; Schleifenzähler verringern
	brne SMIDS1										; Sprung, wenn noch nicht fertig
	ldi SendIDState, 0
SMIDS2:	
	pop cx
	pop ax
	ret

; #################################################################
; ### Senden ein Maus-Datenpaket über die Serielle Schnittstelle
; #################################################################
UART_SendMouseData:
	; der Aufbau der ersten 3 Bytes sind bei Logitech und MS-Wheel Maus gleich
	ldi ax, 0x40				; Das wird das erste zu sendende Byte (Bit 6 ist immer 1)
	sbrc MouseButtonState, 0	; Linke Maustaste gedrückt -> nein, dann nächsten Befehl überspringen
	ori ax, 0x20				; Buttonstatus der Linke Maustaste setzen
	sbrc MouseButtonState, 1	; Rechte Maustaste gedrückt -> nein, dann nächsten Befehl überspringen
	ori ax, 0x10				; Buttonstatus der Linke Maustaste setzen
	sbrc MouseY, 7				; Bit 7 der Y-Koordinate gesetzt -> nein, dann nächsten Befehl überspringen
	ori ax, 0x08				; Bit setzen
	sbrc MouseY, 6				; Bit 6 der Y-Koordinate gesetzt -> nein, dann nächsten Befehl überspringen
	ori ax, 0x04				; Bit setzen
	sbrc MouseX, 7				; Bit 7 der X-Koordinate gesetzt -> nein, dann nächsten Befehl überspringen
	ori ax, 0x02				; Bit setzen
	sbrc MouseX, 6				; Bit 6 der X-Koordinate gesetzt -> nein, dann nächsten Befehl überspringen
	ori ax, 0x01				; Bit setzen
	mov DummyMB, ax
	rcall UART_WriteByte		; Erstes Datenbyte über die Serielle Schnittstelle senden
	mov ax, MouseX				; Bewegung in X-Richtung nach AX
	andi ax, 0x3F				; die obersten 2 Bits sind immer null
	mov DummyMX, ax
	rcall UART_WriteByte		; zweites Datenbyte über die Serielle Schnittstelle senden
	mov ax, MouseY				; Bewegung in Y-Richtung nach AX
	andi ax, 0x3F				; die obersten 2 Bits sind immer null
	mov DummyMY, ax
	rcall UART_WriteByte		; drittes Datenbyte über die Serielle Schnittstelle senden
	cpi MouseType, MouseType_MicrosoftWheelMouse
	breq USMD_WheelMouse
	; Mousetype = Logitech
	sbrs MouseButtonState, 2	; Mittlere Maustaste gedrückt? Wenn Ja, viertes Datenbyte senden
	rjmp USMD_Fertig			; wenn nein, dann zum Ende springen
	ldi ax, 0x20				; Bit 5 Setzen
	mov DummyMZ, ax
	rcall UART_WriteByte		; viertes Datenbyte über die Serielle Schnittstelle senden (nur wenn die Mittlere Taste gedrückt ist)
	rjmp USMD_Fertig			; zum Ende springen
USMD_WheelMouse:	
	; Mousetype = Wheelmouse
	mov ax, MouseZ				; Scrollradbewegung nach ax
	andi ax, 0x0F				; wir nutzen nur die unteren 4 BIT's der Scrollbewegung
	sbrs MouseButtonState, 2	; Mittlere Maustaste gedrückt? -> nein, dann nächsten Befehl überspringen
	ori ax, 0x10				; wenn Ja, dann das 4. Bit setzen
	rcall UART_WriteByte		; virtes Datenbyte über die Serielle Schnittstelle senden
USMD_Fertig:
	ret

MouseIDString_Logitech:					; ID bei Logitech: 'M3'
	.db 2, "M3", 0						; das erste Byte gibt die Anzahl der zu sendenden Bytes an
MouseIDString_Wheelmouse:				; ID bei MS Wheel: 'MZ@', 0, 0, 0
	.db 6, "MZ@", 0, 0, 0, 0			; das erste Byte gibt die Anzahl der zu sendenden Bytes an
