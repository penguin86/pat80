; VIDEO COMPOSITE PAL IO DEVICE
; Implemented following timings in http://blog.retroleum.co.uk/electronics-articles/pal-tv-timing-and-voltages/

.include "atmega1284definition.asm"

; define constant
.equ SYNC_PIN = PD7		; Sync pin is on Port D 7 (pin 21)
.equ VIDEO_PIN = PD6	; Video pin is on Port D 6 (pin 20)

; start vector
.org 0x0000
	rjmp	main			; jump to main label

; main program
main:
	sbi	DDRD, SYNC_PIN		; set pin as output
	sbi	DDRD, VIDEO_PIN		; set pin as output

v_refresh_loop:
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
	ldi r16, 2
	h_picture_outer_loop:
		ldi r17, 152	; line counter
		h_picture_loop:
			; start line sync: 4uS, 96 cycles @ 24Mhz
			cbi	PORTD, SYNC_PIN	; sync goes low (0v)					; 2 cycle
			ldi r18, 32													; 1 cycle
			l_sync_pulse_loop: ; requires 3 cpu cycles
				dec r18													; 1 cycle
				brne l_sync_pulse_loop  								; 2 cycle if true, 1 if false
			sbi	PORTD, SYNC_PIN	; sync goes high (0.3v)
			; end line sync

			; start back porch: 8uS, 192 cycles @ 24Mhz
			ldi r18, 64													; 1 cycle
			l_sync_back_porch_loop:
				dec r18													; 1 cycle
				brne l_sync_back_porch_loop  							; 2 cycle if true, 1 if false
			; end back porch

			; start image: 52uS, 1247 cycles @ 24Mhz
			; 3 bande da 416 cicli

			sbi	PORTD, VIDEO_PIN	; video goes high					; 2 cycle

			ldi r18, 138													; 1 cycle
			l_sync_video_loop1:
				dec r18													; 1 cycle
				brne l_sync_video_loop1  								; 2 cycle if true, 1 if false

			cbi	PORTD, VIDEO_PIN	; video goes low

			ldi r18, 137												; 1 cycle
			l_sync_video_loop2:
				dec r18													; 1 cycle
				brne l_sync_video_loop2 								; 2 cycle if true, 1 if false

			sbi	PORTD, VIDEO_PIN	; video goes high

			ldi r18, 138												; 1 cycle
			l_sync_video_loop3:
				dec r18													; 1 cycle
				brne l_sync_video_loop3  								; 2 cycle if true, 1 if false
			cbi	PORTD, VIDEO_PIN	; video goes low

			; end image

			dec r17 ; decrement line counter
			brne h_picture_loop	; if not 0, repeat h_picture_loop

		dec r16 ; decrement outside counter
		brne h_picture_outer_loop	; if not 0, repeat h_picture_loop
	; end picture lines

	; start 6 short sync pulses
	call short_sync
	call short_sync
	call short_sync
	call short_sync
	call short_sync
	; end 6 short sync pulses

	jmp v_refresh_loop
; end vertical refresh

long_sync:
	; long sync: 30uS low (719 cycles @ 24Mhz), 2uS high (48 cycles @ 24Mhz)
	cbi	PORTD, SYNC_PIN	; sync goes low (0v)					; 2 cycle

	ldi r18, 120												; 1 cycle
	long_sync_low_loop: ; requires 6 cpu cycles
		nop														; 1 cycle
		nop														; 1 cycle
		nop														; 1 cycle
		dec r18													; 1 cycle
		brne long_sync_low_loop  								; 2 cycle if true, 1 if false

	sbi	PORTD, SYNC_PIN	; sync goes high (0.3v)

	ldi r18, 16													; 1 cycle
	long_sync_high_loop: ; requires 3 cpu cycles
		dec r18													; 1 cycle
		brne long_sync_high_loop  								; 2 cycle if true, 1 if false

	ret

short_sync:
	; short sync: 2uS low (48 cycles @ 24Mhz), 30uS high
	cbi	PORTD, SYNC_PIN	; sync goes low (0v)					; 2 cycle

	ldi r18, 16													; 1 cycle
	short_sync_low_loop: ; requires 3 cpu cycles
		dec r18													; 1 cycle
		brne long_sync_low_loop  								; 2 cycle if true, 1 if false

	sbi	PORTD, SYNC_PIN	; sync goes high (0.3v)

	ldi r18, 120												; 1 cycle
	short_sync_high_loop: ; requires 6 cpu cycles
		nop														; 1 cycle
		nop														; 1 cycle
		nop														; 1 cycle
		dec r18													; 1 cycle
		brne short_sync_high_loop  								; 2 cycle if true, 1 if false

	ret