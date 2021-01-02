.include "atmega1284definition.asm"

; define constant
.equ LED_PIN = PD7			; use PD7 as LED pin

; start vector
.org 0x0000
	rjmp	main			; jump to main label

; main program
main:
	sbi	DDRD, LED_PIN		; set LED pin as output
loop:
	sbic	PIND, LED_PIN		; if bit of LED pin is clear, skip next line
 	cbi	PORTD, LED_PIN		; if 1, turn the LED off
	sbis	PIND, LED_PIN		; if bit of LED pin is set, skip next line
 	sbi	PORTD, LED_PIN		; if 0, light the LED up
delay_500ms:
	ldi	r20, 32			; set register, r20 = 32
delay2:
	ldi	r19, 64			; set register, r19 = 64
delay1:
	ldi	r18, 128		; set register, r18 = 128
delay0:
	dec	r18			; decrement register, r18 = r18 - 1
	brne	delay0			; if r18 != 0, jump to label delay0
	dec	r19			; decrement register, r19 = r19 -1
	brne	delay1			; if r19 != 0, jump to label delay1
	dec	r20			; decrement register, r20 = r20 -1
	brne	delay2			; if r20 != 0, jump to label delay2
	rjmp	loop			; if r20 == 0, jump to label loop