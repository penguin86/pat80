; Pat80 BIOS v0.01
; @author: Daniele Verducci
; 
; ROM is at 0x00
; RAM is at 0x80
; LCD is at I/O 0x00 and 0x01



jp sysinit     ; Startup vector: DO NOT MOVE! Must be the first instruction


; SYSTEM CONFIGURATION
LCD_INSTR_REG: EQU %00000000
LCD_DATA_REG: EQU %00000001


; CONSTANTS
SYSINIT_GREETING:
    DB "Pat80 BIOS v0.1",0  ; null terminated string
LIPSUM:
    DB "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",0





include 'driver_hd44780.asm'

; System initialization
sysinit:
    call lcd_init

    ; write characters to display
    ld bc, SYSINIT_GREETING
    call lcd_print      ; write string to screen

    ld bc, LIPSUM
    call lcd_print

    ;call lcd_cls        ; clear screen

    halt



