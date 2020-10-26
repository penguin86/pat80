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
    DB "Pat80 BIOS v0.1     ",0  ; null terminated string










; System initialization
sysinit:
    call lcd_init

    ; write characters to display
    ld bc, SYSINIT_GREETING
    call lcd_write      ; write string to screen
    call lcd_cls        ; clear screen

    halt


lcd_init:
    ;reset procedure
    ld a,0x38
    out (LCD_INSTR_REG),a
    ld a,0x08
    out (LCD_INSTR_REG),a
    ld a,0x01
    out (LCD_INSTR_REG),a

    ;init procedure
    ld a,0x38
    out (LCD_INSTR_REG),a
    ld a,0x0F
    out (LCD_INSTR_REG),a

    ret

; Writes text starting from current cursor position
; @param BC Pointer to a null-terminated string first character
lcd_write:
    ld a, (bc)  ; bc is the pointer to passed string's first char
    cp 0        ; compare A content with 0 (subtract 0 from value and set zero flag Z if result is 0)
    ret z       ; if prev compare is true (Z flag set), string is finished, return
    out (LCD_DATA_REG),a    ; output char
    inc bc ; increment bc to move to next char
    jp lcd_write

; Set cursor position
; @param B X-axis position (0 to 19)
; @param C Y-axis position (0 to 3)
lcd_locate:
    ; TODO
    ret

; Clears the screen
lcd_cls:
    ld a,0x01
    out (LCD_INSTR_REG),a   ; clear display
    ld a,0x02
    out (LCD_INSTR_REG),a   ; cursor to home (top left)
    ret
