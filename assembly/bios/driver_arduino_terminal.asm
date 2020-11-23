; Arduino terminal driver
; @author Daniele Verducci

; config (IO port 0)
DATA_REG: EQU IO_0

; variables
LCD_VAR_SPACE: EQU DRV_VAR_SPACE + 128
incoming_string: EQU LCD_VAR_SPACE

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

; Reads a single character
; @return A The read character
Term_readc:
    in a, (IO_0)    ; reads a character
    cp 0
    jp z, Term_readline     ; if NULL, ignores it and waits for another character
    ret ; if not NULL, returns it in the a register

; Reads a line
; @return BC The pointer to a null-terminated read string
Term_readline:
    ld ix, incoming_string  ; this array will contain read string
    in a, (IO_0)    ; reads a character
    ; if char is 0 (ascii NULL), ignore it
    cp 0
    jp z, Term_readline     ; if 0 (= ascii NULL), ignores it and waits for another character
    ; if char is a newline (CR or LF), line is finished. 
    cp 10 ; CR
    jp z, term_readline_foundcr ; Found newline. Jump to term_readline_foundcr
    cp 13 ; LF
    jp z, term_readline_foundcr ; Found newline. Jump to term_readline_foundcr
    ; At this point the read character is a valid ascii character
    ld (ix), a ; adds char to the read string
    inc ix  ; point to next array position
    jp Term_readline
    term_readline_foundcr:   ; called when carriage return was found (end of line)
    ld (ix), 0 ; Null-terminate string
    ld bc, incoming_string  ; Returns read string
    ret
