; Arduino terminal driver
; @author Daniele Verducci

; config (IO port 0)
DATA_REG: EQU IO_0

; functions

; Sends string
; @param BC Pointer to a null-terminated string first character
Term_print:
    ld a, (bc)  ; bc is the pointer to passed string's first char
    cp 0        ; compare A content with 0 (subtract 0 from value and set zero flag Z if result is 0)
    ret z       ; if prev compare is true (Z flag set), string is finished, return
    out (DATA_REG),a    ; output char
    inc bc ; increment bc to move to next char
    jp Term_print

; Writes a single character
; @param A Value of character to print
Term_printc:
    out (DATA_REG),a
    ret
