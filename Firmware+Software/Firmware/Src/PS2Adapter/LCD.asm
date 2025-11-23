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
 * LCD.asm
 *
 *  Created: 11.09.2016
 *   Author: Christian Machill
 */ 

; ### LCD-Funtionen ###
; basierend auf Informationen von 
; http://www.mikrocontroller.net/articles/AVR-Tutorial:_LCD

.equ LCD_DatenMask = ~(0x0F << LCD_PinDB0)

LCD_Initialize:
	push ax
	push bx
	push cx

	in ax, LCD_SteuerDDR						; DDR der Steuerleitungen einlesen 
	ori ax, (1<<LCD_PIN_E) | (1<<LCD_PIN_RS)	; unsere benutzten Pins auf Ausgang setzen
	out LCD_SteuerDDR, ax						; DDR der Steuerleitungen zurückschreiben
	in ax, LCD_DatenDDR							; DDR der Datenleitungen einlesen
	ori ax, (0x0F << LCD_PinDB0)				; unsere benutzten Pins DB0 bis DB3 auf Ausgang setzen
	out LCD_DatenDDR, ax						; DDR der Datenleitungen zurückschreiben

	ldi cx, 6									; ca 30 Millisecunden warten, damit das LCD Zeit für eigene Initialisierung hat
LI1:	
	ldi ax, Wait_5ms
	rcall WaitMS								; ca 5 Millisekunden warten
	dec cx
	brne LI1

	cbi LCD_SteuerPort, LCD_PIN_RS				; LCD_PIN_RS auf 0 setzen

	in bx, LCD_DatenPort						; alten Stand des Datenports einlesen
	andi bx, LCD_DatenMask						; nur die BITs erhalten, die nicht zu unseren Datenports gehören

	ldi ax, (0x03 << LCD_PinDB0)				; eine $3 soll ausgeben werden
	or ax, bx									; alten Stand des Datenports hinzufügen
	out LCD_DatenPort, ax						; und ausgeben 
	ldi cx, 3									; Schleifenzähler setzen - zusammen mus $3 dreimal ausgegeben werden
LI2:	
	rcall LCD_Enable							; E-Puls auslösen
	ldi ax, Wait_5ms
	rcall WaitMS								; kurz warten
	dec cx	
	brne LI2									; wenn noch nicht fertig, dann nochmal

	ldi ax, (0x02 << LCD_PinDB0)				; 4-Bit Modus aktivieren
	or ax, bx									; alten Stand des Datenports hinzufügen
	out LCD_DatenPort, ax						; und ausgeben 
	rcall LCD_Enable							; E-Puls auslösen
	ldi ax, Wait_5ms
	rcall WaitMS								; kurz warten

	ldi ax, 0x28
	rcall LCD_Command

	ldi ax, 0x0C								; Display einschalten, Cursor erstmal aus
	rcall LCD_Command

	ldi ax, 0x06								; Cursor beu Ausgabe erhöhen, Display nicht scrollen
	rcall LCD_Command
	
	pop cx										; benutzte Register wiederherstellen
	pop bx
	pop ax										
	ret											

; Gibt ein einzelnes Zeichen in AX auf dem LCD-Display aus
LCD_PrintChar:
	push bx
	ldi bx, 1
	rcall LCD_Send
	pop bx
	ret

/*; Gibt den Text aus, auf den der Z-Pointer zeigt
LCD_PrintText:
	push ax
	push bx
	push ZH
	push ZL
	ldi bx, 1
LPT2:
	lpm ax, Z+
	tst ax
	breq LPT1
	rcall LCD_Send
	rjmp LPT2
LPT1:
	pop ZL
	pop ZH
	pop bx
	pop ax 
	ret*/

; Gibt den Wert des Registers AX als Dezimalwert auf dem LCD-Display aus
/*LCD_PrintRegisterDezimal:
	push ax					; zu benutzende Register sichern
	push bx
	push cx
	clt						; T-Flag setzen, im T-Flag merken wir uns, ob die 100er Stelle eine Zahl Größer als 0 war
	ldi bx, 1
	mov cx, ax
	ldi ax, '0'-1
LPRD1:
	inc ax
	subi cx, 100
	brcc LPRD1
	subi cx, -100
	cpi ax, '0'
	breq LPRD1a
	rcall LCD_Send
	set
LPRD1a:
	ldi ax, '0'-1
LPRD2:
	inc ax
	subi cx, 10
	brcc LPRD2
	subi cx, -10
	brts LPRD2a
	cpi ax, '0'
	breq LPRD2b
LPRD2a:
	rcall LCD_Send
LPRD2b:
	ldi ax, '0'
	add ax, cx
	rcall LCD_Send
	pop cx
	pop bx
	pop ax
	ret*/

; Gibt den Wert des Registers AX als Hex-Wert auf dem LCD-Display aus
LCD_PrintRegisterHEX:
	push ax
	push bx
	push cx
	push dx
	ldi bx, 1
	ldi cx, 2
	mov dx, ax
	swap ax
LPRH3:
	andi ax, 0x0F
	cpi ax, 10
	brlt LPRH1
	subi ax, -'A'
	subi ax, 10
	rjmp LPRH2
LPRH1:
	subi ax, -'0'
LPRH2:
	rcall LCD_Send
	mov ax, dx
	dec cx
	brne LPRH3
	pop dx
	pop cx
	pop bx
	pop ax
	ret

; LCD_Wait wartet ca 5 Millisekunden
/*LCD_Wait:
	push ax
	push cx
	ldi  ax, ( FREQ * 5 / 607 ) / 1000
LW2:
	ldi  cx, 0xC9
LW1:
	dec  cx
    brne LW1
    dec  ax
    brne LW2
	pop cx
	pop ax
    ret*/

LCD_Command:
	push bx
	ldi bx, 0
	rcall LCD_Send
	pop bx
	ret

; Sendet einen Befehl oder ein Datenbyte an das LCD-Display
; AX = zu sendendes Byte
; wenn BX=0 dann soll ein Befehl gesendet werden
; wenn BX=1 dann soll ein Datenbyte gesendet werden
LCD_Send:
	push ax									; Benutzte Register sichern
	push cx
	push dx
	mov cx, ax								; als erstes den zu sendenden Befehl sichern
	
	; Datenrichtungsregister setzen
	in ax, LCD_SteuerDDR						; DDR der Steuerleitungen einlesen 
	ori ax, (1<<LCD_PIN_E) | (1<<LCD_PIN_RS)	; unsere benutzten Pins auf Ausgang setzen
	out LCD_SteuerDDR, ax						; DDR der Steuerleitungen zurückschreiben
	in ax, LCD_DatenDDR							; DDR der Datenleitungen einlesen
	ori ax, (0x0F << LCD_PinDB0)				; unsere benutzten Pins DB0 bis DB3 auf Ausgang setzen
	out LCD_DatenDDR, ax						; DDR der Datenleitungen zurückschreiben

	; RS entsprechend setzen oder löschen, wenn Datenport und Steuerport verschieden ist
.if LCD_SteuerPort!=LCD_DatenPort
	cpi bx, 0									; Befehl oder Datenbyte ?
	brne LS1
	cbi LCD_SteuerPort, LCD_PIN_RS			; RS auf 0 setzen - wir wollen ja einen Befehl senden
	rjmp LS2
LS1:
	sbi LCD_SteuerPort, LCD_PIN_RS			; RS auf 1 setzen - wir wollen ja einen Datenbyte senden
LS2:
.endif
	; Befehl ausgeben
	mov ax, cx								; Befehlsbyte wieder herstellen
	swap ax									; Nibble tauschen (wir senden das High-Nibble zuerst)
	andi ax, 0x0F							; Sicherstellen, das wir nur die ersten 4 BITS senden
	rcall LCD_DatenbitVerschieben			; auf richtige BIT-Position schieben
.if LCD_SteuerPort==LCD_DatenPort
	cpi bx, 0
	breq LS3
	ori ax, (1<<LCD_PIN_RS)
LS3:
.endif
	out LCD_DatenPort, ax					; Nibble an DatenPort ausgeben
	rcall LCD_Enable						; E-Puls auslösen
	mov ax, cx								; Befehlsbyte wieder herstellen
	andi ax, 0x0F							; jetzt das LOW-Nibble maskieren
	rcall LCD_DatenbitVerschieben			; auf richtige BIT-Position schieben
.if LCD_SteuerPort==LCD_DatenPort
	cpi bx, 0
	breq LS4
	ori ax, (1<<LCD_PIN_RS)
LS4:
.endif
	out LCD_DatenPort, ax					; und an DatenPort ausgeben
	rcall LCD_Enable						; E-Puls auslösen
	ldi dx, Wait_50us
	rcall Wait								; kurz warten

	; Benutzte Register wieder herstellen
	pop dx
	pop cx
	pop ax
	ret

; Löscht den LCD-Screen
LCD_ClrScr:
	push ax
	ldi ax, 1
	rcall LCD_Command
	ldi ax, Wait_5ms
	rcall WaitMS
	pop ax
	ret

; Positioniert den Cursor links oben
LCD_Home:
	push ax
	ldi ax, 2
	rcall LCD_Command
	ldi ax, Wait_5ms
	rcall WaitMS
	pop ax
	ret

; Senden einen E-Puls
LCD_Enable:
	push dx
	sbi LCD_SteuerPort, LCD_PIN_E
	ldi dx, Wait_50us
	rcall Wait
	cbi LCD_SteuerPort, LCD_PIN_E
	pop dx
	ret

; Diese Funktion verschiebt BITS in ax auf die Position, 
; an welcher die 4 Datenports des LCD angeschlossen sind
LCD_DatenbitVerschieben:
	push bx
	ldi bx, LCD_PinDB0						; Pin-Position des ersten Datenbits nach bx
	tst bx									; fängt es bei 0 an ? 
	brne LDV1								; -> Nein dann Sprung
	rjmp LDV2								; -> Ja - Fertig
LDV1:
	lsl ax									; auf richtige Position schieben
	dec bx									; Position verringern
	brne LDV1								; Ferig ? -> wenn nein, dann wiederholen
LDV2:
	pop bx
	ret
