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
 * Allgemeines.asm
 *
 *  Created: 11.09.2016
 *   Author: Christian Machill
 */ 

;### Maustypen
.equ MouseType_Automatik = 0
.equ MouseType_Microsoft = 1
.equ MouseType_Logitech = 2
.equ MouseType_MicrosoftWheelMouse = 3
;### Register
.def ax = r16
.def bx = r17
.def cx = r18
.def dx = r19
.def tx = r20

;.def DummyMB=r21
;.def DummyMX=r22
;.def DummyMY=r24
;.def DummyMZ=r2

.def HardwareSelectedMouse=r21
.def SetMouseTypeAllowed=r22
.def PS2_MouseType = r23
.def SER_MouseType = r24
.def SettingMode = r25
.def CheckRTSWhileWait = r3
.def UART_RTS_OldState = r5
;.def PS2_Resolution = r6
;.def PS2_DataByte1 = r7
;.def PS2_DataByte2 = r8
;.def PS2_DataByte3 = r9
;.def OldMouseButtonState = r9

.def Baudrate = r6
.def OldMouseZ = r10
.def MouseButtonState = r12
.def MouseX = r13
.def MouseY = r14
.def MouseZ = r15

.equ Wait_10us = ( FREQ * 10 / 10 ) / 1000000
.equ Wait_20us = ( FREQ * 20 / 10 ) / 1000000
.equ Wait_50us = ( FREQ * 50 / 10 ) / 1000000
.equ Wait_100us = ( FREQ * 100 / 10 ) / 1000000
.equ Wait_150us = ( FREQ * 150 / 10 ) / 1000000
.equ Wait_200us = ( FREQ * 200 / 10 ) / 1000000
.equ Wait_300us = ( FREQ * 300 / 10 ) / 1000000
;
.equ Wait_1ms = ( FREQ * 1 / 607 ) / 1000
.equ Wait_5ms = ( FREQ * 5 / 607 ) / 1000
.equ Wait_10ms = ( FREQ * 10 / 607 ) / 1000
;.equ Wait_150ms = ( FREQ * 150 / 607 ) / 1000

; Wartet die in dx angegebenen us
Wait:
    dec  dx
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	brne Wait
	ret

; Wartet die in AX angegebenen ms
WaitMS:
	push cx
WaitMS2:
	ldi  cx, 0xC9
WaitMS1:
	dec  cx
    brne WaitMS1
    dec  ax
    brne WaitMS2
	pop cx
    ret
