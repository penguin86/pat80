; VIDEO COMPOSITE PAL IO DEVICE
;
; INTERFACING WITH PAT80:
; Use PortB as data port. Before writing anything, issue a read (pin RW HIGH) and check the busy pin on the data port. 
; If the busy pin is high, retry reading until goes low. When the busy pin goes low, we have... TODO
;
; ELECTRONICALLY:
; The data port PB0 is tied to ground with a 1KOhm resistance. When the MC is busy drawing the screen, the data port is in
; high impedance state, so that avoids causing bus contention, but when read returns a 0bXXXXXXX0 byte. When the MC starts vsync,
; begins checking the port for data... TODO
;
; PINS:
; Video:
;     Video pin: PA0 (pin 1) (but all PORTA is used)
;     Sync pin: PC0 (pin 22)
; Communication:
;     Data port is PORTB [INPUT]
;     CLK (clock) signal is on PORTD0 [INPUT]
;     RS (register select) on PORTD1 [INPUT]
;     BUSY signal is on PORTD2 [OUTPUT]
; Debug:
;     Debug hsync single pulse on pin: PC1 (pin 23) (may be disabled)
;

.include "m1284def.inc" ; Atmega 1280 device definition

; *** reserved registers ***
; Cursor Position
;     POS_COLUMN (0-103) represents the column on a pair of rows: 0 to 51 is the first row, 52 to 103 the second one
;     POS_ROWP (0-152) represent the pair of rows. POS_ROWP = 5 means the 10th and 11th rows
;     POS_FINE represents fine position (bit inside coarse-position-pointed chunk) in graphic mode.
.def POS_COLUMN = r21
.def POS_ROWP = r20
.def POS_FINE = r24
; Internal registers
.def A = r0	; accumulator
.def STATUS = r25	; signal status (see STATUS TABLE)
;POS_COARSE = Y	; coarse position (aligned to character column)
;DRAWING_BYTE = X	; current position in framebuffer
.def LINE_COUNTER = r23
.def VG_HIGH_ACCUM = r22 ; an accumulator in high registers to be used only by video_generator in interrupt
.def HIGH_ACCUM = r16 ; an accumulator in high registers to be used outside of interrupts

; define constant
.equ VIDEO_PORT_OUT = PORTA		; Used all PORTA, but connected only PA0
.equ SYNC_PIN = PC0			; Sync pin (pin 22)
.equ DEBUG_PIN = PC1		; DEBUG: Single vertical sync pulse to trigger oscilloscope (pin 23)
.equ DATA_PORT_IN = PINB
.equ CLK_PIN = PD0
.equ RS_PIN = PD1
.equ BUSY_PIN = PD2

; memory
.equ FRAMEBUFFER = 0x0100
.equ FRAMEBUFFER_END = 0x2AB0

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
	sbi	DDRC, BUSY_PIN		; set pin as output
	cbi DDRD, CLK_PIN		; set pin as input
	ldi	HIGH_ACCUM, 0xFF
	out DDRA, HIGH_ACCUM			; set port as output (contains video pin)
	ldi	HIGH_ACCUM, 0x00
	out DDRB, HIGH_ACCUM			; set port as input (used as data bus)

	; clear ram
	;*** Load data into ram ***
	; Set X to 0x0100
	ldi r27, high(FRAMEBUFFER)
	ldi r26, low(FRAMEBUFFER)
	load_mem_loop:
		clr r17
		st X+, r17
		; if reached the last framebuffer byte, exit cycle
		cpi r27, 0b00111110
		brne load_mem_loop	; if not 0, repeat h_picture_loop
		cpi r26, 0b11000000
		brne load_mem_loop	; if not 0, repeat h_picture_loop

	; test draw character routine
	call cursor_pos_home
	ldi r19, 14
	dctest:
		ldi r18, 0x21
		draw_chars:
			mov HIGH_ACCUM, r18
			call draw_char
			inc r18
			cpi r18, 0x7E
			brne draw_chars
		dec r19
		brne dctest



	; *** timer setup (use 16-bit counter TC1) ***
	; The Power Reduction TC1 and TC3 bits in the Power Reduction Registers (PRR0.PRTIM1 and
	; PRR1.PRTIM3) must be written to zero to enable the TC1 and TC3 module.
	ldi HIGH_ACCUM, 0b00000000
	sts	PRR0, HIGH_ACCUM
	; Set timer prescaler to 1:1
    LDI HIGH_ACCUM,0b00000001
    sts TCCR1B,HIGH_ACCUM
	; Enambe timer1 overflow interrupt
    LDI HIGH_ACCUM,0b00000001
    STS TIMSK1,HIGH_ACCUM
	; Enable interrupts globally
    SEI
	; Timer setup completed.

	; Wait for data (it never exits)
	; jmp comm_init

	forever:
		jmp forever




.include "video_generator.asm" ; Asyncronous timer-interrupt-based video generation
.include "character_generator.asm" ; Character generator
.include "communication.asm" ; Communication with Pat80
.include "font.asm"	; Font face
