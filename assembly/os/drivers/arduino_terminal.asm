; Arduino terminal driver
; @author Daniele Verducci

; config (IO port 0)
TERM_DATA_REG: EQU IO_0
TERM_DATA_AVAIL_REG: EQU IO_0 + 1

; variables
TERM_VAR_SPACE: EQU DRV_VAR_SPACE + 128
incoming_string: EQU TERM_VAR_SPACE

; functions

; Sends string
; @param BC Pointer to a null-terminated string first character
Term_print:
    ld a, (bc)  ; bc is the pointer to passed string's first char
    cp 0        ; compare A content with 0 (subtract 0 from value and set zero flag Z if result is 0)
    ret z       ; if prev compare is true (Z flag set), string is finished, return
    out (TERM_DATA_REG),a    ; output char
    inc bc ; increment bc to move to next char
    jp Term_print

; Writes a single character
; @param A Value of character to print
Term_printc:
    out (TERM_DATA_REG),a
    ret

; Reads a single character. 0s are ignored (can be used with keyboard).
; Doesn't check DATA_AVAILABLE register of parallel port, because a 0 byte
; is ignored anyway (it represents the ASCII NUL control char).
; @return A The read character
Term_readc:
    in a, (TERM_DATA_REG)    ; reads a character
    add a, 0
    jp z, Term_readc     ; if char is 0 (NULL), ignores it and waits for another character
    ret ; if not NULL, returns it in the a register

; Reads a line. 0s are ignored (can be used with keyboard)
; Doesn't check DATA_AVAILABLE register of parallel port, because a 0 byte
; is ignored anyway (it represents the ASCII NUL control char).
; @return BC The pointer to a null-terminated read string
Term_readline:
    ld bc, incoming_string  ; this array will contain read string
    in a, (TERM_DATA_REG)    ; reads a character
    ; if char is 0 (ascii NULL), ignore it
    add a, 0
    jp z, Term_readline     ; if 0 (= ascii NULL), ignores it and waits for another character
    ; if char is a newline (CR or LF), line is finished.
    cp 10 ; CR
    jp z, term_readline_foundcr ; Found newline. Jump to term_readline_foundcr
    cp 13 ; LF
    jp z, term_readline_foundcr ; Found newline. Jump to term_readline_foundcr
    ; At this point the read character is a valid ascii character
    ld (bc), a ; adds char to the read string
    inc bc  ; point to next array position
    jp Term_readline
    term_readline_foundcr:   ; called when carriage return was found (end of line)
    ;ld (bc), 0 ; Null-terminate string
    ld bc, incoming_string  ; Returns read string pointer
    ret

; Reads the first available byte on the serial port using the DATA register.
; Waits for the Terminal DATA_AVAILABLE register to be non-zero before reading.
; 0s are not ignored (cannot be used with keyboard)
; Affects NO condition bits!
; @return the available byte, even if 0
Term_readb:
    in a, (TERM_DATA_AVAIL_REG)
    cp 0
    jp z, Term_readb
    in a, (TERM_DATA_REG)    ; reads a byte
    ret