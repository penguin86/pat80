; Keyboard driver
; @author Daniele Verducci
;
; Requires declaration of following pointers, one for every column of the keys grid:
; KEYB_A0_REG
; KEYB_A1_REG
; KEYB_A2_REG
; KEYB_A3_REG
; KEYB_A4_REG
; These address must be exclusive if a decoder is not present.
;
; Example (no decoder):
; KEYB_A0_REG = 0000001
; KEYB_A1_REG = 0000010
; KEYB_A2_REG = 0000100
; KEYB_A3_REG = 0001000
; etc...
;
; Example (with decoder):
; KEYB_A0_REG = 0000000
; KEYB_A1_REG = 0000001
; KEYB_A2_REG = 0000010
; KEYB_A3_REG = 0000011
; etc...


; Reads the keyboard
; @return: a 0-terminated array of keycodes representing the pressed keys
Keyb_read:
    in (KEYB_A0_REG),a
