; *******************************************
; *    PAT80 COMPOSITE PAL VIDEO ADAPTER    *
; *         Communication module            *
; *******************************************

; This module manages the communication between Pat80 and
; the video adapter.

; INTERNAL POINTER:
; Internally, the last screen position is represented by 24 bits in two registers:
; POS_COARSE: Register Y (16-bit, r31 and r30): Coarse position. Points to one of the chunks
;    (character columns). 46 chunks per row, 304 rows. Used for character position, as
;    1 chunk = 1 byte = 1 character.
; POS_FINE: Register r24: Fine position. Represents the bit inside the chunk selected by POS_COARSE.
;    Ignored in character mode (the character is always aligned to column). Used in graphic mode.

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

