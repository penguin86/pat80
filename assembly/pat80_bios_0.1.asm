; SYSTEM CONFIGURATION
LCD_INSTR_REG: EQU %00000000
LCD_DATA_REG: EQU %00000001

; System initialization
call lcd_init

; write characters to display
ld bc, hello_world
call lcd_write      ; write string to screen

halt


lcd_init:
    ;reset procedure
    ld a,%00111000
    out (LCD_INSTR_REG),a
    ld a,%00001000
    out (LCD_INSTR_REG),a
    ld a,%00000001
    out (LCD_INSTR_REG),a

    ;init procedure
    ld a,%00111000
    out (LCD_INSTR_REG),a
    ld a,%00001110
    out (LCD_INSTR_REG),a

    ret

lcd_write:
    ld a, (bc)  ; bc is the pointer to passed string's first char
    cp 0        ; compare A content with 0 (subtract 0 from value and set zero flag Z if result is 0)
    ret z       ; if prev compare is true (Z flag set), string is finished, return
    out (LCD_DATA_REG),a    ; output char
    inc bc ; increment bc to move to next char
    jp lcd_write

hello_world:
    DB "Lorem ipsum",0  ; null terminated string