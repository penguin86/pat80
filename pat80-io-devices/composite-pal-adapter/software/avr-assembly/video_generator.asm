; *******************************************
; *    PAT80 COMPOSITE PAL VIDEO ADAPTER    *
; *        Video generator module           *
; *******************************************

; Uses registers X(R27, R26), STATUS (R25), VG_HIGH_ACCUM (r24), LINE_COUNTER (r23)

; Implemented following timings in http://blog.retroleum.co.uk/electronics-articles/pal-tv-timing-and-voltages/ and http://www.kolumbus.fi/pami1/video/pal_ntsc.html
; Every line, for 46 times, it loads a byte from memory into PORTA register and then shifts the byte to the left to show another bit (do it 7 times)
; This also displays byte's MSB pixel "for free", as the video pin is PD7 (last bit of PORTA).

; This module generates a Composite PAL monochrome signal with a resolution
; of 416x304 pixels of which only 368x248 pixels are visible (= 46x28 characters).
; The signal is generated using 16-bit Timer1 and interrupts.


; How does it work:
; The screen draw is divided in phases. Every phase does something. I.e. phases 0 to 9
; represents the first 5 long syncs:
; (sync goes low, wait 30uS, sync goes high, wait 2uS) x 5 times = 10 phases
; When the interrupt is called, it uses register STATUS to decide what to do.
;
; STATUS TABLE:
; reg STATUS: Current status (what the interrupt should do when fired):
;	0-9 = long sync
;	10-19 = short sync
;   20-44 = draw empty lines (top vertical padding)
;	45 = draw lines (draw 304 lines complete with line sync and back porch, then start short
;		sync: sync pin low and next interrupt after 2uS)
;   46-70 = draw empty lines (bottom vertical padding)
;	71-82 = short sync
;	83-255 = invalid state or screen draw finished: set to 0 and restart from first long sync start

.equ TIMER_DELAY_60US = 65535 - 1409 	; 719 cycles @ 24Mhz (minus overhead)
.equ TIMER_DELAY_30US = 65535 - 690 	; 719 cycles @ 24Mhz (minus overhead)
.equ TIMER_DELAY_2US = 65535 - 17		; 48 cycles @ 24Mhz (minus overhead)
.equ TIMER_DELAY_4US = 65535 - 60		; 96 cycles @ 24Mhz (minus overhead)
.equ BACK_PORCH_DELAY = 234				; 186 cycles back porch + 48 cycles to leave 2 chunks empty (image padding)


; ********* FUNCTIONS CALLED BY INTERRUPT ***********
on_tim1_ovf:
	; TODO: save BUSY pin status and restore it before RETI, because it could be in BUSY status when interrupted
	; set BUSY pin to indicate the mc is unresponsive from now on
	sbi PORTD, BUSY_PIN
	; called by timer 1 two times per line (every 32 uS) during hsync, unless drawing picture.
	inc STATUS
	; if STATUS > 146 then STATUS=0
	cpi STATUS, 147	; TODO: Added a seventh sync pulse at end of screen because at the first short sync after the image, the timer doesn't tick at the right time
	brlo switch_status
	clr STATUS
	; check status and decide what to do
	switch_status:
		cpi STATUS, 10
		brlo long_sync	; 0-9: long sync
		cpi STATUS, 20
		brlo short_sync	; 10-19: short sync
		cpi STATUS, 90
		brlo empty_line	; 20-89: empty lines
		breq start_draw_picture ; 90: draw picture
		cpi STATUS, 135
		brlo empty_line	; 91-134 = draw empty lines
		jmp short_sync  ; 135-146 = short sync
	; reti is at end of all previous jumps

start_draw_picture:
	jmp draw_picture	; the breq instruction can branch only relatively -63 to +64

long_sync:
	; long sync: 30uS low (719 cycles @ 24Mhz), 2uS high (48 cycles @ 24Mhz)

	sbis PORTC, SYNC_PIN	; if sync is high (sync is not occuring) skip next line
	jmp long_sync_end
	; sync pin is high (sync is not occuring)
	cbi	PORTC, SYNC_PIN	; sync goes low (0v)					; 2 cycle
	; set timer in 30uS (reset timer counter)
	ldi XH, high(TIMER_DELAY_30US)
	ldi XL, low(TIMER_DELAY_30US)
	sts	TCNT1H,XH
	sts	TCNT1L,XL
	; clear BUSY pin to indicate the mc is again responsive from now on
	cbi PORTD, BUSY_PIN
	reti

	long_sync_end:
		; sync pin is low (sync is occuring)
		sbi	PORTC, SYNC_PIN	; sync goes high (0.3v)
		; set timer in 2uS:
		ldi XH, high(TIMER_DELAY_2US)
		ldi XL, low(TIMER_DELAY_2US)
		sts	TCNT1H,XH
		sts	TCNT1L,XL
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
	ldi XH, high(TIMER_DELAY_2US)
	ldi XL, low(TIMER_DELAY_2US)
	sts	TCNT1H,XH
	sts	TCNT1L,XL
	; clear BUSY pin to indicate the mc is again responsive from now on
	cbi PORTD, BUSY_PIN
	reti

	short_sync_end:
		; sync pin is low (sync is occuring)
		sbi	PORTC, SYNC_PIN	; sync goes high (0.3v)
		; set timer in 30uS:
		ldi XH, high(TIMER_DELAY_30US)
		ldi XL, low(TIMER_DELAY_30US)
		sts	TCNT1H,XH
		sts	TCNT1L,XL
		; clear BUSY pin to indicate the mc is again responsive from now on
		cbi PORTD, BUSY_PIN
		reti

empty_line:
	; line sync: 4uS low (96 cycles @ 24Mhz), 60uS high (1440 cycles @ 24Mhz)
	sbis PORTC, SYNC_PIN	; if sync is high (sync is not occuring) skip next line
	jmp empty_line_end
	; sync pin is high (sync is not occuring)
	cbi	PORTC, SYNC_PIN	; sync goes low (0v)					; 2 cycle
	; set timer in 2uS (reset timer counter)
	ldi XH, high(TIMER_DELAY_4US)
	ldi XL, low(TIMER_DELAY_4US)
	sts	TCNT1H,XH
	sts	TCNT1L,XL
	; clear BUSY pin to indicate the mc is again responsive from now on
	cbi PORTD, BUSY_PIN
	reti

	empty_line_end:
		; sync pin is low (sync is occuring)
		sbi	PORTC, SYNC_PIN	; sync goes high (0.3v)
		; set timer in 30uS:
		ldi XH, high(TIMER_DELAY_60US)
		ldi XL, low(TIMER_DELAY_60US)
		sts	TCNT1H,XH
		sts	TCNT1L,XL
		; clear BUSY pin to indicate the mc is again responsive from now on
		cbi PORTD, BUSY_PIN
		reti

draw_picture:
	; set X register to framebuffer start
	ldi XH, high(FRAMEBUFFER)
	ldi XL, low(FRAMEBUFFER)

	; start 248 picture lines
	ldi LINE_COUNTER, SCREEN_HEIGHT-1	; line counter
	h_picture_loop:
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
		ldi VG_HIGH_ACCUM, BACK_PORCH_DELAY/3									; 1 cycle
		l_sync_back_porch_loop:
			dec VG_HIGH_ACCUM									; 1 cycle
			brne l_sync_back_porch_loop  							; 2 cycle if true, 1 if false
		; **** end back porch

		call draw_line	; 3 cycles (+ 3 to come back to on_line_drawn)

		dec LINE_COUNTER ; decrement line countr					; 1 cycle
		brne h_picture_loop	; if not 0, repeat h_picture_loop		; 2 cycle if true, 1 if false
	; end picture lines

	; video pin goes low before sync
	clr VG_HIGH_ACCUM											; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM							; 1 cycle

	; immediately start first end-screen short sync:
	inc STATUS
	jmp short_sync
	; reti is in short_sync
; end draw_picture


draw_line:
	; NO loops, as this is time-strict
	; 46 chunks of 8 pixels

	; chunk 1
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 2
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 3
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 4
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 5
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 6
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 7
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 8
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 9
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 10
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 11
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 12
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 13
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 14
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 15
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 16
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 17
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 18
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 19
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 20
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 21
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 22
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 23
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 24
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 25
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 26
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 27
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 28
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 29
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 30
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 31
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 32
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 33
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 34
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 35
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 36
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 37
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 38
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 39
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 40
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 41
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 42
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 43
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 44
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 45
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; chunk 46
	ld VG_HIGH_ACCUM, X+	; load pixel	; 2 cycles
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle
	nop							; 1 cycle
	lsr VG_HIGH_ACCUM						; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM				; 1 cycle

	; blank right margin (write 0 to video port and wait)
	clr VG_HIGH_ACCUM					; 1 cycle
	out VIDEO_PORT_OUT, VG_HIGH_ACCUM	; 1 cycle
	ldi VG_HIGH_ACCUM, 28									; 1 cycle
	eol_porch_loop: ; requires 3 cpu cycles
		dec VG_HIGH_ACCUM									; 1 cycle
		brne eol_porch_loop									; 2 if jumps, 1 if continues

	ret
