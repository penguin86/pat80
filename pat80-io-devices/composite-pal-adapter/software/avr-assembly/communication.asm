; *******************************************
; *    PAT80 COMPOSITE PAL VIDEO ADAPTER    *
; *         Communication module            *
; *******************************************

; This module manages the communication between Pat80 and
; the video adapter.
; The data port is PORTB. The CLK (clock) signal is on PORTD0
; and the RS (register select) on PORTD1

; Initializes and waits for a byte on PORTB
comm_init:
    ; Set Z to framebuffer start
	ldi r31, high(FRAMEBUFFER<<1)
	ldi r30, low(FRAMEBUFFER<<1)
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

