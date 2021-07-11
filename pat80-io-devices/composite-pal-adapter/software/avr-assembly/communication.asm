; *******************************************
; *    PAT80 COMPOSITE PAL VIDEO ADAPTER    *
; *         Communication module            *
; *******************************************
;
; @language: AVR ASM
;
; This file is part of Pat80 IO Devices.
;
; Pat80 IO Devices is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; Pat80 IO Devices is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with Pat80 IO Devices.  If not, see <http://www.gnu.org/licenses/>.
;
;
; This module manages the communication between Pat80 and
; the video adapter.

; INTERNAL POINTER:
; Internally, the last screen position is represented by 24 bits in two registers:
; POS_COARSE: Register Y (16-bit, r31 and r30): Coarse position. Points to one of the chunks
;    (character columns). 46 chunks per row, 304 rows. Used for character position, as
;    1 chunk = 1 byte = 1 character.

; Initializes and waits for a byte on PORTB
comm_init:
	call cursor_pos_home ; Set cursor to 0,0
    comm_wait_byte:
        in HIGH_ACCUM, DATA_PORT_IN   ; read PORTB
        ; Check continuously CLK until a LOW is found
        sbic PORTD, CLK_PIN
        jmp comm_wait_byte
        ; CLK triggered: Draw char
        call draw_char
        jmp comm_wait_byte

        ; ; CLK triggered: Copy PORTB to the next framebuffer byte
        ; st Y+, A
        ; ; if reached the last framebuffer byte, exit cycle
		; cpi r31, 0b00111110
		; brne comm_wait_byte	; if not 0, repeat h_picture_loop
		; cpi r30, 0b11000000
		; brne comm_wait_byte	; if not 0, repeat h_picture_loop
        ; jmp comm_init ; filled all memory: reset framebuffer position

