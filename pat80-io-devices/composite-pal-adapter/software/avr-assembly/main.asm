; VIDEO COMPOSITE PAL IO DEVICE
; Implemented following timings in http://blog.retroleum.co.uk/electronics-articles/pal-tv-timing-and-voltages/
; Every line, for 52 times, it loads a byte from memory into PORTD register and then shifts the byte to the left to show another bit (do it 7 times)
; This also displays byte's MSB pixel "for free", as the video pin is PD7 (last bit of PORTD).
;
; PINS:
; Video pin: PD0 (pin 14)
; Sync pin: PC0 (pin 22)
; Debug hsync pin: PC1 (pin 23)

.include "atmega1284definition.asm"

; define constant
.equ SYNC_PIN = PC0		; Sync pin (pin 22)
.equ DEBUG_PIN = PC1	; DEBUG: Single vertical sync pulse to trigger oscilloscope (pin 23)

; memory
.equ FRAMEBUFFER = 0x100

; start vector
.org 0x0000
	rjmp	main			; jump to main label

; main program
main:
	sbi	DDRC, SYNC_PIN		; set pin as output
	sbi	DDRC, DEBUG_PIN		; set pin as output
	ldi	r16, 0xFF
	out DDRD, r16			; set port as output (contains video pin)






;*** Load data into ram ***
; Set X to 0x0100
ldi r27, high(FRAMEBUFFER<<1)
ldi r26, low(FRAMEBUFFER<<1)
; Set Z to 0x1000 (cat image)
ldi r31, high(CAT_IMAGE<<1)
ldi r30, low(CAT_IMAGE<<1)


load_mem_loop:
	lpm r17, Z+
	;ldi r17, 0b00001111
	st X+, r17
	; if reached the last framebuffer byte, exit cycle
	cpi r27, 0b00111110
	brne load_mem_loop	; if not 0, repeat h_picture_loop
	cpi r26, 0b11000000
	brne load_mem_loop	; if not 0, repeat h_picture_loop


v_refresh_loop:
	; set X register to framebuffer start 0x0100
	; (set it a byte before, because it will be incremented at first)
	clr r27
	ldi r26, 0xFF

	; start 5 long sync pulses
	call long_sync
	call long_sync
	call long_sync
	call long_sync
	call long_sync
	; end 5 long sync pulses

	; start 5 short sync pulses
	call short_sync
	call short_sync
	call short_sync
	call short_sync
	call short_sync
	; end 5 short sync pulses

	; start 304 picture lines
	ldi r17, 152	; line counter
	h_picture_loop:
		; debug
		; sbi	PORTC, DEBUG_PIN	; high
		; cbi	PORTC, DEBUG_PIN	; low
		; debug

		; ***************** DRAW FIRST LINE *********************

		; **** start line sync: 4uS, 96 cycles @ 24Mhz
		; video pin goes low before sync
		clr r19						; 1 cycle
		out PORTD, r19				; 1 cycle
		
		cbi	PORTC, SYNC_PIN	; sync goes low (0v)					; 2 cycle
		ldi r18, 31													; 1 cycle
		l_sync_pulse_loop: ; requires 3 cpu cycles
			dec r18													; 1 cycle
			brne l_sync_pulse_loop  								; 2 cycle if true, 1 if false
		sbi	PORTC, SYNC_PIN	; sync goes high (0.3v)
		; **** end line sync

		; **** start line back porch: 8uS, 192 cycles @ 24Mhz
		; leave time at the end for line setup and draw_line call
		ldi r18, 62													; 1 cycle
		l_sync_back_porch_loop:
			dec r18													; 1 cycle
			brne l_sync_back_porch_loop  							; 2 cycle if true, 1 if false
		; **** end back porch

		call draw_line	; 3 cycles (+ 3 to come back to on_line_drawn)
		; **** draws line pixels: 52uS, 1248 cycles @ 24Mhz ****



		; ***************** DRAW SECOND LINE *********************

		; **** start line sync: 4uS, 96 cycles @ 24Mhz
		; video pin goes low before sync
		clr r19						; 1 cycle
		out PORTD, r19				; 1 cycle

		cbi	PORTC, SYNC_PIN	; sync goes low (0v)					; 2 cycle
		ldi r18, 31													; 1 cycle
		l_sync_pulse_loop2: ; requires 3 cpu cycles
			dec r18													; 1 cycle
			brne l_sync_pulse_loop2  								; 2 cycle if true, 1 if false
		sbi	PORTC, SYNC_PIN	; sync goes high (0.3v)
		; **** end line sync

		; **** start line back porch: 8uS, 192 cycles @ 24Mhz
		; leave time at the end for line setup and draw_line call
		ldi r18, 62													; 1 cycle
		l_sync_back_porch_loop2:
			dec r18													; 1 cycle
			brne l_sync_back_porch_loop2  							; 2 cycle if true, 1 if false
		; **** end back porch

		call draw_line	; 3 cycles (+ 3 to come back to on_line_drawn)
		; **** draws line pixels: 52uS, 1248 cycles @ 24Mhz ****




		; debug
		; sbi	PORTC, DEBUG_PIN	; high
		; cbi	PORTC, DEBUG_PIN	; low
		; debug

		dec r17 ; decrement line countr								; 1 cycle
		brne h_picture_loop	; if not 0, repeat h_picture_loop		; 2 cycle if true, 1 if false
	; end picture lines

	; video pin goes low before sync
	clr r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	; start 6 short sync pulses
	call short_sync
	call short_sync
	call short_sync
	call short_sync
	call short_sync
	call short_sync
	; end 6 short sync pulses

	; debug
	; sbi	PORTC, DEBUG_PIN	; high
	; cbi	PORTC, DEBUG_PIN	; low
	; debug

	jmp v_refresh_loop
; end vertical refresh

long_sync:
	; long sync: 30uS low (719 cycles @ 24Mhz), 2uS high (48 cycles @ 24Mhz)
	cbi	PORTC, SYNC_PIN	; sync goes low (0v)					; 2 cycle

	ldi r18, 120												; 1 cycle
	long_sync_low_loop: ; requires 6 cpu cycles
		nop														; 1 cycle
		nop														; 1 cycle
		nop														; 1 cycle
		dec r18													; 1 cycle
		brne long_sync_low_loop  								; 2 cycle if true, 1 if false

	sbi	PORTC, SYNC_PIN	; sync goes high (0.3v)

	ldi r18, 15													; 1 cycle
	long_sync_high_loop: ; requires 3 cpu cycles
		dec r18													; 1 cycle
		brne long_sync_high_loop  								; 2 cycle if true, 1 if false

	ret

short_sync:
	; short sync: 2uS low (48 cycles @ 24Mhz), 30uS high (720 cycles @ 24Mhz)
	cbi	PORTC, SYNC_PIN	; sync goes low (0v)					; 2 cycle

	ldi r18, 15  												; 1 cycle
	short_sync_low_loop: ; requires 3 cpu cycles
		dec r18													; 1 cycle
		brne short_sync_low_loop  								; 2 cycle if true, 1 if false

	sbi	PORTC, SYNC_PIN	; sync goes high (0.3v)

	ldi r18, 120												; 1 cycle
	short_sync_high_loop: ; requires 6 cpu cycles
		nop														; 1 cycle
		nop														; 1 cycle
		nop														; 1 cycle
		dec r18													; 1 cycle
		brne short_sync_high_loop  								; 2 cycle if true, 1 if false

	ret


draw_line:
	; NO loops, as this is time-strict
	; 52 chunks of 8 pixels

	; chunk 1
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 2
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 3
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 4
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 5
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 6
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 7
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 8
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 9
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 10
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 11
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 12
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 13
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 14
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 15
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 16
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 17
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 18
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 19
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 20
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 21
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 22
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 23
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 24
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 25
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 26
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 27
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 28
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 29
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 30
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 31
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 32
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 33
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 34
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 35
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 36
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 37
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 38
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 39
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 40
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 41
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 42
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 43
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 44
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 45
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 46
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 47
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 48
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 49
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 50
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 51
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	; chunk 52
	ld r19, X+	; load pixel	; 2 cycles
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle
	nop							; 1 cycle
	lsl r19						; 1 cycle
	out PORTD, r19				; 1 cycle

	ret


.include "cat2.asm"