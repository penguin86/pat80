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

; LCD config (IO port 0)
LCD_INSTR_REG: EQU IO_0
LCD_DATA_REG: EQU IO_0 + 1

; Keyboard config (IO port 1)
KEYB_A0_REG: EQU IO_1 + %00000001
KEYB_A1_REG: EQU IO_1 + %00000010
KEYB_A2_REG: EQU IO_1 + %00000100
KEYB_A3_REG: EQU IO_1 + %00001000
KEYB_A4_REG: EQU IO_1 + %00010000


; CONSTANTS
SYSINIT_GREETING:
    DB "Pat80",0  ; null terminated string





include 'driver_hd44780.asm'
include 'driver_keyboard.asm'

; System initialization
Sysinit:
    call Lcd_init

    ; position to line 2 char 3
    ;ld b, 1
    ;ld c, 1
    ;call Lcd_locate
    
    ; write characters to display
    ld bc, SYSINIT_GREETING
    call Lcd_print      ; write string to screen

    ; poll keyboard
    _poll_keyb:
    call Keyb_read
    jp _poll_keyb

