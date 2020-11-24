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
;   I/O 0 (0x00 - 0x1F) LCD (uses 0x00 and 0x01)
;   I/O 1 (0x20 - 0x3F)
;   I/O 2 (0x40 - 0x5F)
;   I/O 3 (0x60 - 0x7F)
;   I/O 4 (0x80 - 0x9F)
;   I/O 5 (0xA0 - 0xBF)
;   I/O 6 (0xC0 - 0xDF)
;   I/O 7 (0xE0 - 0xFF)


; MEMORY CONFIGURATION
SYS_VAR_SPACE: EQU 0x8000
DRV_VAR_SPACE: EQU 0x9000
APP_VAR_SPACE: EQU 0xA000

; SYSTEM CONFIGURATION
IO_0: EQU 0x00
IO_1: EQU 0x20
IO_2: EQU 0x40
IO_3: EQU 0x60
IO_4: EQU 0x80
IO_5: EQU 0xA0
IO_6: EQU 0xC0
IO_7: EQU 0xE0



; CONSTANTS
SYSINIT_GREETING:
    DB "Pat80",10,0  ; null terminated string





;include 'driver_hd44780.asm'
;include 'driver_keyboard.asm'
include 'driver_arduino_terminal.asm'

; SYSTEM CALLS
; User I/O

; Prints string
; @param BC Pointer to a null-terminated string first character
Print:
    call Term_print
    ret

; Writes a single character
; @param A Value of character to print
Printc:
    call Term_printc
    ret

; Reads a single character
; @return A The read character
Readc:
    call Term_readc
    ret

; Reads a line
; @return BC The pointer to a null-terminated read string
Readline:
    call Term_readline
    ret

; System initialization
Sysinit:
    ld bc, SYSINIT_GREETING
    call Print
   
    _io_test_loop:
        call Readline
        call Print

        ; call Printc
        ; call Readline
        ; ld a, (bc)
        ; cp a, 0
        ; jp z, _io_test_loop
        ; ld (APP_VAR_SPACE), bc
        ; ld bc, SAYS
        ; call Print
        ; ld bc, (APP_VAR_SPACE)
        ; call Print
    jp _io_test_loop


