; Vgax display driver
; @author Daniele Verducci
;
; Requires declaration of following pointers:
; VGAX_INSTR_REG
; VGAX_DATA_REG

; variables
lcd_cur_x: EQU DRV_VAR_SPACE
lcd_cur_y: EQU lcd_cur_x + 1

; functions

; Inits the lcd display
Lcd_init:
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
Lcd_print:
    ld a, (bc)  ; bc is the pointer to passed string's first char
    cp 0        ; compare A content with 0 (subtract 0 from value and set zero flag Z if result is 0)
    ret z       ; if prev compare is true (Z flag set), string is finished, return
    out (LCD_DATA_REG),a    ; output char
    inc bc ; increment bc to move to next char
    ; increment x position
    ld a, (lcd_cur_x)
    inc a
    ld (lcd_cur_x), a
    ; if x position > 19, increment y position and set x to 0
    ld a, (lcd_cur_x)
    cp 20
    jp nz, Lcd_print    ; if x position is not 20, continue cycle
    ld a, 0
    ld (lcd_cur_x), a   ; else set x to 0
    ; and increment y
    ld a, (lcd_cur_y)
    inc a
    ld (lcd_cur_y), a
    ; if y > 3 set y to 0
    cp 4    ; a still contains lcd_cur_y: compare with 4
    jp nz, Lcd_print    ; if y position is not 4, continue cycle
    ld a, 0
    ld (lcd_cur_x), a   ; else set y pos to 0
    jp Lcd_print
    ret

; Writes a single character at current cursror position
; @param A Value of character to print
Lcd_printc:
    out (LCD_DATA_REG),a
    ret


; Set cursor position
; @param B X-axis position (0 to 19)
; @param C Y-axis position (0 to 3)
Lcd_locate:
    ld a, b
    ld (lcd_cur_x), a
    ld a, c
    ld (lcd_cur_y), a
    call lcd_locate
    ret

; private
; The cursor position can seem like black magic but it makes much more sense once you know that the HD44780 is designed to control a 40 character 4-line display. So if you have a 16×2 then you will only see the first 16 characters of the top two lines. Simple enough once you get used to taking these character positions into account. For example, in a 16×2 display, the first line is position 0-15. So 0x80 is the first position, 0x80 + 12 = 0x8C is the 13th (remember, they are zero indexed). The second line is a little tricky since it shows positions 64-79. Just add the position number (in decimal) to 0x80 (in hex) to get the hex address of the cursor position. The address is the command to move the cursor to that location. So, to move to the 13th position of the top line in a 16×2 Sparkfun Display, I would send “0xFE 0x8C”. The first byte warns the onboard microcontroller that a command is coming, and the second byte is the command.
lcd_locate:
    ; warns the lcd microcontroller that a command is coming
    ld a, 0xFE
    out (LCD_INSTR_REG),a
    ; get line start command code from array
    ld hl, LCD_LINES_LEFT ; load array pointer
    ld bc, lcd_cur_y ; load line number
    ld b, 0 ; since line number is only 8 bit, clean garbage on the upper bit
    add hl, bc  ; sum first array element to line number to access correct array element. Now hl contains array pointer
    ; now sum x offset to the start line code to obtain lcd controller complete position code
    ld a, (lcd_cur_x)   ; load cursor x position
    add a, (hl)         ; sum cursor x pos to line start code. Result is in a
    out (LCD_INSTR_REG),a   ; send cursor position to lcd controller
    ret

; Clears the screen
Lcd_cls:
    ld a,0x01
    out (LCD_INSTR_REG),a   ; clear display
    ld a,0x02
    out (LCD_INSTR_REG),a   ; cursor to home (top left)
    ret
