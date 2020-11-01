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


jp Sysinit     ; Startup vector: DO NOT MOVE! Must be the first instruction


; SYSTEM CONFIGURATION
IO_0: EQU 0x00
IO_1: EQU 0x20
IO_2: EQU 0x40
IO_3: EQU 0x60
IO_4: EQU 0x80
IO_5: EQU 0xA0
IO_6: EQU 0xC0
IO_7: EQU 0xE0

LCD_INSTR_REG: EQU IO_0
LCD_DATA_REG: EQU IO_0 + 1

SYS_VAR_SPACE: EQU 0x8000
DRV_VAR_SPACE: EQU 0x9000
APP_VAR_SPACE: EQU 0xA000


; CONSTANTS
SYSINIT_GREETING:
    DB "Pat80",0  ; null terminated string
LIPSUM:
    DB "Lorem ipsum dolor siadipiscing elit. Sedt amet, consectetur  dapibus nec nullam.",0





include 'driver_hd44780.asm'

; System initialization
Sysinit:
    call Lcd_init

    ; position to line 2 char 3
    ;ld b, 1
    ;ld c, 1
    ;call Lcd_locate
    
    ; write characters to display
    ;ld bc, SYSINIT_GREETING
    ;call Lcd_print      ; write string to screen

    ld bc, LIPSUM
    call Lcd_print

    ;call count


    ; IO TEST
    iotest:
    ; do not test 0: is lcd
    ld a,0x00
    out (IO_1),a
    ld a,0x00
    out (IO_2),a
    ld a,0x00
    out (IO_3),a
    ld a,0x00
    out (IO_4),a
    ld a,0x00
    out (IO_5),a
    ld a,0x00
    out (IO_6),a
    ld a,0x00
    out (IO_7),a

    call Lcd_cls        ; clear screen

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
