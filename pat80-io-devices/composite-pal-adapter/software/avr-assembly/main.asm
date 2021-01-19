; VIDEO COMPOSITE PAL IO DEVICE
; Implemented following timings in http://blog.retroleum.co.uk/electronics-articles/pal-tv-timing-and-voltages/
; Every line, for 52 times, it loads a byte from memory into PORTA register and then shifts the byte to the left to show another bit (do it 7 times)
; This also displays byte's MSB pixel "for free", as the video pin is PD7 (last bit of PORTA).
;
; INTERFACING WITH PAT80:
; Use PortB as data port. Before writing anything, issue a read (pin RW HIGH) and check the busy pin on the data port. 
; If the busy pin is high, retry reading until goes low. When the busy pin goes low, we have... TODO
;
; ELECTRONICALLY:
; The data port D0 (= PB0) is tied to ground with a 1KOhm resistance. When the MC is busy drawing the screen, the data port is in
; high impedance state, so that avoids causing bus contention, but when read returns a 0bXXXXXXX0 byte. When the MC starts vsync,
; begins checking the port for data... TODO
;
; PINS:
; Video pin: PA0 (pin 1)
; Sync pin: PC0 (pin 22)
; Debug hsync pin: PC1 (pin 23)
;
; STATUS TABLE:
; R25 (STATUS): Current status (what the interrupt should do when fired):
;	0-9 = long sync
;	10-19 = short sync
;	20 = draw lines (draw 304 lines complete with line sync and back porch, then start short
;		sync: sync pin low and next interrupt after 2uS)
;	21-32 = short sync
;	33-255 = invalid state or screen draw finished: set to 0 and restart from first long sync start

.include "m1284def.inc"

; registers
.def A = r0	; accumulator
.def STATUS = r25	; signal status (see STATUS TABLE)

; define constant
.equ SYNC_PIN = PC0			; Sync pin (pin 22)
.equ DEBUG_PIN = PC1		; DEBUG: Single vertical sync pulse to trigger oscilloscope (pin 23)
.equ TIMER_DELAY_30US = 65535 - 690 	; 719 cycles @ 24Mhz (minus overhead)
.equ TIMER_DELAY_2US = 65535 - 17		; 48 cycles @ 24Mhz (minus overhead)

; memory
.equ FRAMEBUFFER = 0x100

; start vector
.org 0x0000
	rjmp	main			; reset vector: jump to main label
.org 0x001E
	rjmp	on_tim1_ovf		; interrupt for timer 1 overflow

.org 0x40
; main program
main:
	; pins setup
	sbi	DDRC, SYNC_PIN		; set pin as output
	sbi	DDRC, DEBUG_PIN		; set pin as output
	ldi	r16, 0xFF
	out DDRA, r16			; set port as output (contains video pin)


	; *** Load data into ram ***
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

	; *** timer setup (use 16-bit counter TC1) ***
	; The Power Reduction TC1 and TC3 bits in the Power Reduction Registers (PRR0.PRTIM1 and
	; PRR1.PRTIM3) must be written to zero to enable the TC1 and TC3 module.
	ldi r16, 0b00000000
	sts	PRR0, r16
<<<<<<< HEAD
	ldi r16, 0b00000001
	sts	PRR1, r16
	; Set TCNT1 (timer counter) to 0xFF00 (the timer will trigger soon)
	ser	r27
	sts	TCNT1H,r27
	clr r26
	sts	TCNT1L,r26
	; Set prescaler to 1:1 (TCCR1B is XXXXX001)
	ldi r16, 0b00000001
	sts	TCCR1B, r16
	; Clear pending interrupts
	ldi r16, 0b00000001
	out TIFR1,r16
	; Enable timer1 overflow interrupt(TOIE1): the interrupt 1 will be fired when timer resets
	ldi r16, 0b00000001
	sts	TIMSK1, r16
	; The Global Interrupt Enable bit must be set for the interrupts to be enabled.
	ldi r16, 0b10000000
	sts	SREG, r16
=======
	; Set timer prescaler to 1:1
    LDI r16,0b00000001
    sts TCCR1B,r16
	; Enambe timer1 overflow interrupt
    LDI r16,0b00000001
    STS TIMSK1,r16
	; Enable interrupts globally
    SEI
	; Timer setup completed.
>>>>>>> 901fe50fee42333cc45884e4d9913128272ce175

	; loop forever
	forever:
		jmp forever


; ********* FUNCTIONS CALLED BY INTERRUPT ***********
on_tim1_ovf:
	; debug
	; sbi	PORTC, DEBUG_PIN	; high
	; cbi	PORTC, DEBUG_PIN	; low
	; ; set timer in 30uS (reset timer counter)
	; ldi r27, high(TIMER_DELAY_30US)
	; ldi r26, low(TIMER_DELAY_30US)
	; sts	TCNT1H,r27
	; sts	TCNT1L,r26
	; reti
	; debug





	; called by timer 1 two times per line (every 32 uS) during hsync, unless drawing picture.
	inc STATUS
	; if STATUS >= 33 then STATUS=0
	cpi STATUS, 35	; TODO: Added a seventh sync pulse at end of screen because at the first short sync after the image, the timer doesn't tick at the right time
	brlo switch_status
	clr STATUS
	; check status and decide what to do
	switch_status:
		cpi STATUS, 10
		brlo long_sync	; 0-9: long sync
		cpi STATUS, 20
		breq draw_picture ; 20: draw picture
		jmp short_sync  ; 10-19 or 21-32: short_sync
	; reti is at end of all previous jumps

draw_picture:
	; set X register to framebuffer start 0x0100
	; (set it a byte before, because it will be incremented at first)
	clr r27
	ldi r26, 0xFF

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
		out PORTA, r19				; 1 cycle

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
		out PORTA, r19				; 1 cycle

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
	out PORTA, r19				; 1 cycle

	; debug
	; sbi	PORTC, DEBUG_PIN	; high
	; cbi	PORTC, DEBUG_PIN	; low
	; debug


	; immediately start first end-screen short sync:
	inc STATUS
	jmp short_sync
	; reti is in short_sync
; end draw_picture

long_sync:
	; long sync: 30uS low (719 cycles @ 24Mhz), 2uS high (48 cycles @ 24Mhz)

	sbis PORTC, SYNC_PIN	; if sync is high (sync is not occuring) skip next line
	jmp long_sync_end
	; sync pin is high (sync is not occuring)
	cbi	PORTC, SYNC_PIN	; sync goes low (0v)					; 2 cycle
	; set timer in 30uS (reset timer counter)
	ldi r27, high(TIMER_DELAY_30US)
	ldi r26, low(TIMER_DELAY_30US)
	sts	TCNT1H,r27
	sts	TCNT1L,r26
	reti

	long_sync_end:
		; sync pin is low (sync is occuring)
		sbi	PORTC, SYNC_PIN	; sync goes high (0.3v)
		; set timer in 2uS:
		ldi r27, high(TIMER_DELAY_2US)
		ldi r26, low(TIMER_DELAY_2US)
		sts	TCNT1H,r27
		sts	TCNT1L,r26
		reti


short_sync:
	; short sync: 2uS low (48 cycles @ 24Mhz), 30uS high (720 cycles @ 24Mhz)

	sbis PORTC, SYNC_PIN	; if sync is high (sync is not occuring) skip next line
	jmp short_sync_end
	; sync pin is high (sync is not occuring)
	cbi	PORTC, SYNC_PIN	; sync goes low (0v)					; 2 cycle
	; set timer in 2uS (reset timer counter)
	ldi r27, high(TIMER_DELAY_2US)
	ldi r26, low(TIMER_DELAY_2US)
	sts	TCNT1H,r27
	sts	TCNT1L,r26
	reti

	short_sync_end:
		; sync pin is low (sync is occuring)
		sbi	PORTC, SYNC_PIN	; sync goes high (0.3v)
		; set timer in 30uS:
		ldi r27, high(TIMER_DELAY_30US)
		ldi r26, low(TIMER_DELAY_30US)
		sts	TCNT1H,r27
		sts	TCNT1L,r26
		reti


draw_line:
	; NO loops, as this is time-strict
	; 52 chunks of 8 pixels

	; chunk 1
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 2
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 3
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 4
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 5
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 6
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 7
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 8
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 9
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 10
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 11
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 12
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 13
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 14
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 15
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 16
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 17
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 18
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 19
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 20
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 21
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 22
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 23
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 24
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 25
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 26
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 27
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 28
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 29
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 30
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 31
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 32
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 33
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 34
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 35
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 36
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 37
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 38
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 39
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 40
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 41
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 42
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 43
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 44
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 45
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 46
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 47
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 48
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 49
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 50
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 51
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	; chunk 52
	ld r0, X+	; load pixel	; 2 cycles
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle
	nop							; 1 cycle
	lsr r0						; 1 cycle
	out PORTA, r0				; 1 cycle

	ret


.include "cat.asm"