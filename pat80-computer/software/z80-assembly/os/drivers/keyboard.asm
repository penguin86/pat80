; Keyboard driver
; Direct keyboard grid control (direct keys addressing, without keyboard controller)
; @author Daniele Verducci
; @language: Z80 ASM
;
;
; This file is part of Pat80 Memory Monitor.
;
; Pat80 Memory Monitor is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; Pat80 Memory Monitor is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with Pat80 Memory Monitor.  If not, see <http://www.gnu.org/licenses/>.
;
;
; Requires declaration of following pointers, one for every column of the keys grid:
; KEYB_A0_REG
; KEYB_A1_REG
; KEYB_A2_REG
; KEYB_A3_REG
; KEYB_A4_REG
; These address must be exclusive if a decoder is not present.
;
; Example (no decoder):
; KEYB_A0_REG = 0000001
; KEYB_A1_REG = 0000010
; KEYB_A2_REG = 0000100
; KEYB_A3_REG = 0001000
; etc...
;
; Example (with decoder):
; KEYB_A0_REG = 0000000
; KEYB_A1_REG = 0000001
; KEYB_A2_REG = 0000010
; KEYB_A3_REG = 0000011
; etc...

; Keyboard config (IO port 1)
KEYB_A0_REG: EQU IO_1 + %00000001
KEYB_A1_REG: EQU IO_1 + %00000010
KEYB_A2_REG: EQU IO_1 + %00000100
KEYB_A3_REG: EQU IO_1 + %00001000
KEYB_A4_REG: EQU IO_1 + %00010000

; Reads the keyboard
; @return: a 0-terminated array of keycodes representing the pressed keys
Keyb_read:
    in a, (KEYB_A0_REG)
    cp 0
    jp z, _keyb_read_a1
    add a, %01000000
    call Lcd_printc     ; A already contains char to print
    _loop:
    in a, (KEYB_A0_REG)
    cp 0
    jp nz, _loop
    ret
    _keyb_read_a1:
    in a, (KEYB_A1_REG)
    cp 0
    ret z
    add a, %01010000
    call Lcd_printc     ; A already contains char to print
    _loop2:
    in a, (KEYB_A1_REG)
    cp 0
    jp nz, _loop2
    ret
