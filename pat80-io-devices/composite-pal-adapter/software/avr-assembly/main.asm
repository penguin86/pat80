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

.include "m1284def.inc" ; Atmega 1280 device definition

; reserved registers
.def A = r0	; accumulator
.def STATUS = r25	; signal status (see STATUS TABLE)

; define constant
.equ SYNC_PIN = PC0			; Sync pin (pin 22)
.equ DEBUG_PIN = PC1		; DEBUG: Single vertical sync pulse to trigger oscilloscope (pin 23)
.equ CLK_PIN = PD7

; memory
.equ FRAMEBUFFER = 0x100

; start vector
.org 0x0000
	rjmp	main			; reset vector: jump to main label
.org 0x001E
	rjmp	on_tim1_ovf		; interrupt for timer 1 overflow (used by video generation)

.org 0x40
; main program
main:
	; pins setup
	sbi	DDRC, SYNC_PIN		; set pin as output
	sbi	DDRC, DEBUG_PIN		; set pin as output
	cbi DDRD, CLK_PIN		; set pin as input
	ldi	r16, 0xFF
	out DDRA, r16			; set port as output (contains video pin)
	ldi	r16, 0x00
	out DDRB, r16			; set port as input (used as data bus)
	


	; *** timer setup (use 16-bit counter TC1) ***
	; The Power Reduction TC1 and TC3 bits in the Power Reduction Registers (PRR0.PRTIM1 and
	; PRR1.PRTIM3) must be written to zero to enable the TC1 and TC3 module.
	ldi r16, 0b00000000
	sts	PRR0, r16
	; Set timer prescaler to 1:1
    LDI r16,0b00000001
    sts TCCR1B,r16
	; Enambe timer1 overflow interrupt
    LDI r16,0b00000001
    STS TIMSK1,r16
	; Enable interrupts globally
    SEI
	; Timer setup completed.

	; Wait for data (it never exits)
	jmp comm_init

	forever:
		jmp forever




.include "video_generator.asm" ; Asyncronous timer-interrupt-based video generation
.include "character_generator.asm" ; Character generator
.include "communication.asm" ; Communication with Pat80
