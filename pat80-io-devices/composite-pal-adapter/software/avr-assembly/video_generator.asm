; *******************************************
; *    PAT80 COMPOSITE PAL VIDEO ADAPTER    *
; *        Video generator module           *
; *******************************************

; This module generates a Composite PAL monochrome signal with a resolution
; of 416x304 pixels of which only 376x232 pizels are visible (= 47x29 characters).
; The signal is generated using 16-bit Timer1 and interrupts.


; How does it work:
; The screen draw is divided in phases. Every phase does something. I.e. phases 0 to 9
; represents the first 5 long syncs:
; (sync goes low, wait 30uS, sync goes high, wait 2uS) x 5 times = 10 phases
; When the interrupt is called, it uses register r25 (STATUS) to decide what to do.
;
; STATUS TABLE:
; R25 (STATUS): Current status (what the interrupt should do when fired):
;	0-9 = long sync
;	10-19 = short sync
;	20 = draw lines (draw 304 lines complete with line sync and back porch, then start short
;		sync: sync pin low and next interrupt after 2uS)
;	21-32 = short sync
;	33-255 = invalid state or screen draw finished: set to 0 and restart from first long sync start

.equ TIMER_DELAY_30US = 65535 - 690 	; 719 cycles @ 24Mhz (minus overhead)
.equ TIMER_DELAY_2US = 65535 - 17		; 48 cycles @ 24Mhz (minus overhead)


; ********* FUNCTIONS CALLED BY INTERRUPT ***********
on_tim1_ovf:
	; TODO: save BUSY pin status and restore it before RETI, because it could be in BUSY status when interrupted
	; set BUSY pin to indicate the mc is unresponsive from now on
	sbi PORTD, BUSY_PIN
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
	; save X register
	push XH
	push XL

	; set X register to framebuffer start 0x0100
	; (set it a byte before, because it will be incremented at first)
	clr r27
	ldi r26, 0xFF

	; start 304 picture lines
	ldi LINE_COUNTER, 152	; line counter
	h_picture_loop:
		; ***************** DRAW FIRST LINE *********************

		; **** start line sync: 4uS, 96 cycles @ 24Mhz
		; video pin goes low before sync
		clr VG_HIGH_ACCUM										; 1 cycle
		out VIDEO_PORT_OUT, VG_HIGH_ACCUM						; 1 cycle

		cbi	PORTC, SYNC_PIN	; sync goes low (0v)					; 2 cycle
		ldi VG_HIGH_ACCUM, 31									; 1 cycle
		l_sync_pulse_loop: ; requires 3 cpu cycles
			dec VG_HIGH_ACCUM									; 1 cycle
			brne l_sync_pulse_loop  								; 2 cycle if true, 1 if false
		sbi	PORTC, SYNC_PIN	; sync goes high (0.3v)
		; **** end line sync

		; **** start line back porch: 8uS, 192 cycles @ 24Mhz
		; leave time at the end for line setup and draw_line call
		ldi VG_HIGH_ACCUM, 62									; 1 cycle
		l_sync_back_porch_loop:
			dec VG_HIGH_ACCUM									; 1 cycle
			brne l_sync_back_porch_loop  							; 2 cycle if true, 1 if false
		; **** end back porch

		call draw_line	; 3 cycles (+ 3 to come back to on_line_drawn)
		; **** draws line pixels: 52uS, 1248 cycles @ 24Mhz ****



		; ***************** DRAW SECOND LINE *********************

		; **** start line sync: 4uS, 96 cycles @ 24Mhz
		; video pin goes low before sync
		clr VG_HIGH_ACCUM										; 1 cycle
		out VIDEO_PORT_OUT, VG_HIGH_ACCUM						; 1 cycle

		cbi	PORTC, SYNC_PIN	; sync goes low (0v)					; 2 cycle
		ldi VG_HIGH_ACCUM, 31									; 1 cycle
		l_sync_pulse_loop2: ; requires 3 cpu cycles
			dec VG_HIGH_ACCUM									; 1 cycle
			brne l_sync_pulse_loop2  								; 2 cycle if true, 1 if false
		sbi	PORTC, SYNC_PIN	; sync goes high (0.3v)
		; **** end line sync

		; **** start line back porch: 8uS, 192 cycles @ 24Mhz
		; leave time at the end for line setup and draw_line call
		ldi VG_HIGH_ACCUM, 62									; 1 cycle
		l_sync_back_porch_loop2:
			dec VG_HIGH_ACCUM									; 1 cycle
			brne l_sync_back_porch_loop2  							; 2 cycle if true, 1 if false
		; **** end back porch

		call draw_line	; 3 cycles (+ 3 to come back to on_line_drawn)
		; **** draws line pixels: 52uS, 1248 cycles @ 24Mhz ****

		dec LINE_COUNTER ; decrement line countr					; 1 cycle
		brne h_picture_loop	; if not 0, repeat h_picture_loop		; 2 cycle if true, 1 if false
	; end picture lines

	; restore X register
	pop XL
	pop XH

	; video pin goes low before sync
	clr VG_HIGH_ACCUM											; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM							; 1 cycle

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
	; clear BUSY pin to indicate the mc is again responsive from now on
	cbi PORTD, BUSY_PIN
	reti

	long_sync_end:
		; sync pin is low (sync is occuring)
		sbi	PORTC, SYNC_PIN	; sync goes high (0.3v)
		; set timer in 2uS:
		ldi r27, high(TIMER_DELAY_2US)
		ldi r26, low(TIMER_DELAY_2US)
		sts	TCNT1H,r27
		sts	TCNT1L,r26
		; clear BUSY pin to indicate the mc is again responsive from now on
		cbi PORTD, BUSY_PIN
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
	; clear BUSY pin to indicate the mc is again responsive from now on
	cbi PORTD, BUSY_PIN
	reti

	short_sync_end:
		; sync pin is low (sync is occuring)
		sbi	PORTC, SYNC_PIN	; sync goes high (0.3v)
		; set timer in 30uS:
		ldi r27, high(TIMER_DELAY_30US)
		ldi r26, low(TIMER_DELAY_30US)
		sts	TCNT1H,r27
		sts	TCNT1L,r26
		; clear BUSY pin to indicate the mc is again responsive from now on
		cbi PORTD, BUSY_PIN
		reti


draw_line:
	; NO loops, as this is time-strict
	; 52 chunks of 8 pixels

	; chunk 1
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 2
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 3
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 4
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 5
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 6
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 7
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 8
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 9
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 10
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 11
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 12
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 13
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 14
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 15
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 16
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 17
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 18
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 19
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 20
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 21
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 22
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 23
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 24
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 25
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 26
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 27
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 28
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 29
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 30
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 31
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 32
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 33
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 34
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 35
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 36
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 37
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 38
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 39
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 40
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 41
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 42
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 43
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 44
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 45
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 46
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 47
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 48
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 49
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 50
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 51
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	; chunk 52
	ld A, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle
	nop							; 1 cycle
	lsr A						; 1 cycle
	out VIDEO_PORT_OUT, A				; 1 cycle

	ret
