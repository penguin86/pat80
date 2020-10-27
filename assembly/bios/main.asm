; Pat80 BIOS v0.01
; @author: Daniele Verducci
; 
; ROM is at 0x0000
; RAM is at 0x8000
;   SYSTEM VAR SPACE: 0x8000 - 0x8FFF (4kb)
;   DRIVERS VAR SPACE: 0x9000 - 0x9FFF (4kb)
;   APPLICATION VAR SPACE: 0xA000 - 0xFFFF (24kb)
; LCD is at I/O 0x00 and 0x01



jp sysinit     ; Startup vector: DO NOT MOVE! Must be the first instruction


; SYSTEM CONFIGURATION
LCD_INSTR_REG: EQU %00000000
LCD_DATA_REG: EQU %00000001
SYS_VAR_SPACE: EQU 0x8000
DRV_VAR_SPACE: EQU 0x9000
APP_VAR_SPACE: EQU 0xA000


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

    call lcd_locate

    ld bc, LIPSUM
    call lcd_print

    ;call lcd_cls        ; clear screen

    ;call count

    halt


; count:
;     myVar: EQU APP_VAR_SPACE   ; init variable
;     ld hl, "A"          ; load value into register
;     ld (myVar), hl      ; copy value into variable
;     call count_loop

; count_loop:
;     ld bc, myVar
;     call lcd_print
;     ; increm var
;     ld a, (myVar)
;     inc a
;     ld (myVar), a
;     call count_loop
