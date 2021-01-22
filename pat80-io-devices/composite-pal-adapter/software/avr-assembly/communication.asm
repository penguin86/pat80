; *******************************************
; *    PAT80 COMPOSITE PAL VIDEO ADAPTER    *
; *         Communication module            *
; *******************************************

; This module manages the communication between Pat80 and
; the video adapter.
; The data port is PORTB. The CLK (clock) signal is on PORTD0
; and the RS (register select) on PORTD1

; INTERNAL POINTER:
; Internally, the last screen position is represented by 24 bits in two registers:
; POS_COARSE: Register Z (16-bit, r31 and r30): Coarse position. Points to one of the chunks
;    (character columns). 52 chunks per row, 304 rows. Used for character position, as
;    1 chunk = 1 byte = 1 character.
; POS_FINE: Register r24: Fine position. Represents the bit inside the chunk selected by POS_COARSE.
;    Ignored in character mode (the character is always aligned to column.)

; Initializes and waits for a byte on PORTB
comm_init:
	call cursor_pos_home ; Set cursor to 0,0
    comm_wait_byte:
        in r24, PINB   ; read PORTB
        ; Check continuously CLK until a LOW is found
        sbic PORTD, CLK_PIN
        jmp comm_wait_byte
        ; CLK triggered: Copy PORTB to the next framebuffer byte
        st Z+, r24
        ; if reached the last framebuffer byte, exit cycle
		cpi r31, 0b00111110
		brne comm_wait_byte	; if not 0, repeat h_picture_loop
		cpi r30, 0b11000000
		brne comm_wait_byte	; if not 0, repeat h_picture_loop
        jmp comm_init ; filled all memory: reset framebuffer position

; Sets the cursor to 0,0 and clears fine position
cursor_pos_home:
	; Set Z to framebuffer start
	ldi POS_COARSE_H, high(FRAMEBUFFER<<1)
	ldi POS_COARSE_L, low(FRAMEBUFFER<<1)
	clr POS_FINE
	ret
