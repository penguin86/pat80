; HD44780 20x4 characters LCD display driver
; @author Daniele Verducci

; variables
;lcd_cur_x: EQU DRV_VAR_SPACE
;lcd_cur_y: lcd_cur_x + 1

; functions

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
lcd_print:
    ld a, (bc)  ; bc is the pointer to passed string's first char
    cp 0        ; compare A content with 0 (subtract 0 from value and set zero flag Z if result is 0)
    ret z       ; if prev compare is true (Z flag set), string is finished, return
    out (LCD_DATA_REG),a    ; output char
    inc bc ; increment bc to move to next char

    jp lcd_print

; Set cursor position
; @param B X-axis position (0 to 19)
; @param C Y-axis position (0 to 3)
lcd_locate:
    ld a,0xFE
    out (LCD_INSTR_REG),a   ; warns the lcd microcontroller that a command is coming
    ld a,0xA8
    out (LCD_INSTR_REG),a   ; place cursor to first char of second line
    ret

; Clears the screen
lcd_cls:
    ld a,0x01
    out (LCD_INSTR_REG),a   ; clear display
    ld a,0x02
    out (LCD_INSTR_REG),a   ; cursor to home (top left)
    ret
