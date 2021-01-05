; VIDEO COMPOSITE PAL IO DEVICE
; Implemented following timings in http://blog.retroleum.co.uk/electronics-articles/pal-tv-timing-and-voltages/

.include "atmega1284definition.asm"

; define constant
.equ SYNC_PIN = PC0		; Sync pin (pin 22)
.equ VIDEO_PIN = PD7	; Video pin (pin 21)
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
	out DDRD, r16			; set port as output

	
	; Load ram addr into register X
	ldi r16,0x00
	mov r0,r16
	ldi r16,0x01
	mov r1,r16
	mov XL,r0
	mov XH,r1

	; DEBUG: loads some static data in ram
	ldi r18, 255
	fill_mem_loop1:
		st X+, r18
		dec r18
		brne fill_mem_loop1
	; END DEBUG

v_refresh_loop:
	; reset memory position counter
	;ldi XL, 0x00
	;ldi XH, 0x01
	ldi r16,0x00
	mov r0,r16
	ldi r16,0x01
	mov r1,r16
	mov XL,r0
	mov XH,r1

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
			call line_sync
			; start line pixels: 52uS, 1247 cycles @ 24Mhz
			ldi r18, 52													; 1 cycle
			l_sync_video_loop:	; 24 cycles
				; Load a byte from memory into PORTD register and increment the counter.
				; This also displays byte's MSB pixel "for free", as the video pin is PD7
				; (last bit of PORTD).
				;ld r19, X+					; 2 cycles
				
				ld r19, X					; 1 cycle
				nop

				out PORTD, r19				; 1 cycle
				; Shift the byte to the left to show another bit (do it 7 times)
				lsl r19						; 1 cycle
				out PORTD, r19
				nop
				lsl r19						; 1 cycle
				out PORTD, r19
				nop
				lsl r19						; 1 cycle
				out PORTD, r19
				nop
				lsl r19						; 1 cycle
				out PORTD, r19
				nop
				lsl r19						; 1 cycle
				out PORTD, r19
				nop
				lsl r19						; 1 cycle
				out PORTD, r19
				nop							; 1 cycle
				dec r18						; 1 cycle
				brne l_sync_video_loop			; 2 cycles if jumps (1 if continues)
			; end line pixels

			cbi PORTD, VIDEO_PIN	; video pin goes low before sync
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
	call short_sync
	; end 6 short sync pulses

	; debug
	sbi	PORTC, DEBUG_PIN	; high
	cbi	PORTC, DEBUG_PIN	; low
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

line_sync:
	; line sync & front porch
	; start line sync: 4uS, 96 cycles @ 24Mhz
	cbi	PORTC, SYNC_PIN	; sync goes low (0v)					; 2 cycle
	ldi r18, 32													; 1 cycle
	l_sync_pulse_loop: ; requires 3 cpu cycles
		dec r18													; 1 cycle
		brne l_sync_pulse_loop  								; 2 cycle if true, 1 if false
	sbi	PORTC, SYNC_PIN	; sync goes high (0.3v)
	; end line sync

	; start back porch: 8uS, 192 cycles @ 24Mhz
	ldi r18, 64													; 1 cycle
	l_sync_back_porch_loop:
		dec r18													; 1 cycle
		brne l_sync_back_porch_loop  							; 2 cycle if true, 1 if false
	; end back porch

	ret