jp Sysinit     ; Startup vector: DO NOT MOVE! Must be the first instruction

; Pat80 BIOS v0.01
; @author: Daniele Verducci
;
; MEMORY MAP
;   ROM is at 0x0000
;   RAM is at 0x8000
;       SYSTEM VAR SPACE: 0x8000 - 0x8FFF (4kb)
;       DRIVERS VAR SPACE: 0x9000 - 0x9FFF (4kb)
;       APPLICATION VAR SPACE: 0xA000 - 0xFFFF (24kb)
; I/O MAP
;   I/O 0 (0x00 - 0x1F) Parallel terminal (uses addr 0x00 and 0x01)
;   I/O 1 (0x20 - 0x3F) Sound card (uses addr 0x20 only)
;   I/O 2 (0x40 - 0x5F) PS2 Keyboard (uses 0x40 and 0x41)
;   I/O 3 (0x60 - 0x7F)
;   I/O 4 (0x80 - 0x9F)
;   I/O 5 (0xA0 - 0xBF)
;   I/O 6 (0xC0 - 0xDF)
;   I/O 7 (0xE0 - 0xFF)

; **** RESET/INTERRUPT VECTOR ****

; Maskable interrupt mode 1: when the BREAK key is pressed, 
; a maskable interrupt is generated and the CPU jumps to this address.
; In this way, BREAK key brings up memory monitor at any time.
ds 0x38
	di ; Disable maskable interrupts.
	exx ; exchange registers
	ex af, af'
	jp Monitor_main

; **** SYSTEM CALLS ****
; System calls provide access to low level functions (input from keyboard, output to screen etc).
; The name starts always with Sys_
ds 0x40	; Place system calls after Z80 reset/interrupt subroutines space

; Returns ABI version.
; (ABI -> https://en.wikipedia.org/wiki/Application_binary_interface)
; Any Pat80 application should check the ABI version on startup, and refuse to run if not compatible.
; @return bc the ABI version
Sys_ABI:
    ld bc, 0
    ret

; Prints string
; @param BC Pointer to a null-terminated string first character
Sys_Print:
    jp Term_print

; Writes a single character
; @param A Value of character to print
Sys_Printc:
    jp Term_printc

; Reads a single character
; @return A The read character
Sys_Readc:
    ;jp Term_readc
    jp PS2Keyb_readc

; Reads a line
; @return BC The pointer to a null-terminated read string
Sys_Readline:
    jp Term_readline

; Emits system beep
Sys_Beep:
    jp Snd_beep



; MEMORY CONFIGURATION
SYS_VAR_SPACE: EQU 0x8000
DRV_VAR_SPACE: EQU 0x9000
APP_SPACE: EQU 0xA000

; SYSTEM CONFIGURATION
IO_0: EQU 0x00
IO_1: EQU 0x20
IO_2: EQU 0x40
IO_3: EQU 0x60
IO_4: EQU 0x80
IO_5: EQU 0xA0
IO_6: EQU 0xC0
IO_7: EQU 0xE0






;include 'drivers/hd44780.asm'
;include 'drivers/keyboard.asm'
include 'drivers/ps2_keyboard.asm'
include 'drivers/arduino_terminal.asm'
include 'drivers/sn76489.asm'
include 'monitor.asm'
include 'libs/time.asm'
;include 'tests/sndtest.asm'


; **** SYSTEM INITIALIZATION ****
Sysinit:
    ; Init snd driver
    call Snd_init

    ; Init video
    ; TODO

    ; Wait for audio amp to unmute
    ld bc, TIME_DUR_SECOND
    call Time_delay55

    ; Play startup sound
    call Sys_Beep

	; Run memory monitor
	ei ; enable maskabpe interrupts
	im 1 ; set interrupt mode 1 (on interrupt jumps to 0x38)
	rst 0x38 ; throw fake interrupt: jump to interrupt routine to start monitor

	; User exited from memory monitor without loading a program. Do nothing.
	mloop:
		; Main loop: do nothing.
		jp mloop

    ; DEBUG: Echo chars
    ; loop:
    ;     call Term_readc
    ;     call Term_printc
    ;     jp loop
