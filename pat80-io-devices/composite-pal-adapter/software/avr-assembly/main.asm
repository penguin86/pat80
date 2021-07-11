; VIDEO COMPOSITE PAL IO DEVICE
;
; @language: AVR ASM
;
; This file is part of Pat80 IO Devices.
;
; Pat80 IO Devices is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; Pat80 IO Devices is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with Pat80 IO Devices.  If not, see <http://www.gnu.org/licenses/>.
;
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
; Video generator registers:
; X(R27, R26)
.def STATUS = r25	; signal status (see STATUS TABLE)
.def VG_HIGH_ACCUM = r24 ; an accumulator in high registers to be used only by video_generator in interrupt
.def LINE_COUNTER = r23

; Character generator registers:
.def POS_COLUMN = r22 ; POS_COLUMN (0-46) represents the character/chunk column
.def POS_ROWP = r21 ; POS_ROWP (0-255) represent the chunk row. The caracter row is POS_ROWP/FONT_HEIGHT
.def HIGH_ACCUM = r20 ; an accumulator in high registers to be used outside of interrupts
.def A = r0	; general purpose accumulator to be used outside of interrupts

; Hardware pins and ports
.equ VIDEO_PORT_OUT = PORTA		; Used all PORTA, but connected only PA0
.equ SYNC_PIN = PC0			; Sync pin (pin 22)
.equ DEBUG_PIN = PC1		; DEBUG: Single vertical sync pulse to trigger oscilloscope (pin 23)
.equ DATA_PORT_IN = PIND
.equ CLK_PIN = PC2
.equ RS_PIN = PC3
.equ BUSY_PIN = PC4

; Memory map
.equ FRAMEBUFFER = 0x0F70
.equ FRAMEBUFFER_END = 0x3C00
.equ SCREEN_HEIGHT = 248

; start vector
.org 0x0000
	rjmp	main			; reset vector: jump to main label
.org 0x001E
	rjmp	on_tim1_ovf		; interrupt for timer 1 overflow (used by video generation)

.org 0x40
; main program
main:
	; **** I/O SETUP ****

	; pins setup
	sbi	DDRC, SYNC_PIN		; set pin as output
	sbi	DDRC, DEBUG_PIN		; set pin as output
	sbi	DDRC, BUSY_PIN		; set pin as output
	cbi DDRD, CLK_PIN		; set pin as input
	ldi	HIGH_ACCUM, 0xFF
	out DDRA, HIGH_ACCUM			; set port as output (contains video pin)
	ldi	HIGH_ACCUM, 0x00
	out DDRB, HIGH_ACCUM			; set port as input (used as data bus)


	; **** MEMORY SETUP ****

	call clear_screen

	



	; **** TIMERS AND DRAWING IMAGE ROUTINES SETUP ****

	; Timer setup (use 16-bit counter TC1)
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




	; **** MAIN ROUTINE ****

	; Wait for data (it never exits)
	;jmp comm_init


	; draw example image
	;call draw_cat

	; test draw character routine
	call cursor_pos_home
	dctest:
		ldi r18, 0x41
		draw_chars:
			mov HIGH_ACCUM, r18
			call draw_char
			dc_continue:
			; wait
			ser r19
			dc_wait_loop_1:
				ser r16
				dc_wait_loop_2:
					dec r16
					brne dc_wait_loop_2
				dec r19
				brne dc_wait_loop_1
			; wait
			; ser r19
			; dc_wait_loop_a1:
			; 	ser r16
			; 	dc_wait_loop_a2:
			; 		dec r16
			; 		brne dc_wait_loop_a2
			; 	dec r19
			; 	brne dc_wait_loop_a1
			; ; wait
			; ser r19
			; dc_wait_loop_s1:
			; 	ser r16
			; 	dc_wait_loop_s2:
			; 		dec r16
			; 		brne dc_wait_loop_s2
			; 	dec r19
			; 	brne dc_wait_loop_s1
			; ; wait
			; ser r19
			; dc_wait_loop_d1:
			; 	ser r16
			; 	dc_wait_loop_d2:
			; 		dec r16
			; 		brne dc_wait_loop_d2
			; 	dec r19
			; 	brne dc_wait_loop_d1
			; ; wait
			; ser r19
			; dc_wait_loop_f1:
			; 	ser r16
			; 	dc_wait_loop_f2:
			; 		dec r16
			; 		brne dc_wait_loop_f2
			; 	dec r19
			; 	brne dc_wait_loop_f1

			inc r18
			cpi r18, 0x5B
			brne draw_chars
		call draw_carriage_return
		jmp dctest

	


	forever:
		jmp forever




.include "video_generator.asm" ; Asyncronous timer-interrupt-based video generation
.include "character_generator.asm" ; Character generator
;.include "communication.asm" ; Communication with Pat80
.include "font.asm"	; Font face
;.include "example_data/cat.asm"	; Cat image
