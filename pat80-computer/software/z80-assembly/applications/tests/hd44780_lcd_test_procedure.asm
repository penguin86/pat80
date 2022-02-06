; @language: Z80 ASM
;hd44780 lcd test procedure

LCD_INSTR_REG: EQU %00000000
LCD_DATA_REG: EQU %00000001

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

;write characters to display
ld a,%01000100
out (LCD_DATA_REG),a
ld a,%01100001
out (LCD_DATA_REG),a
ld a,%01101110
out (LCD_DATA_REG),a
ld a,%01101001
out (LCD_DATA_REG),a
ld a,%01100101
out (LCD_DATA_REG),a
ld a,%01101100
out (LCD_DATA_REG),a
ld a,%01100101
out (LCD_DATA_REG),a
ld a,%00100001
out (LCD_DATA_REG),a

halt
