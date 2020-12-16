; Pat80 Memory Monitor
; @author Daniele Verducci
;
; Monitor commands (CMD $arg):
;   H (HELP) Shows available commands
;   D (DUMP) $pos Dumps first 100 bytes of memory starting at $pos
;   S (SET) $pos $val Replaces byte at $pos with $val
;   L (LOAD) $pos $val
;   R (RUN) $pos Starts executing code from $pos
;   A (ADB) Enters in Assembly Depoy Bridge mode: loads all the incoming bytes in application memory and starts executing.
; The commands are entered with a single letter and the program completes the command

include 'libs/strings.asm'

; CONSTANTS
; All monitor commands are 3 chars long.
MON_WELCOME: DB "PAT80 MEMORY MONITOR 0.2",10,0
MON_COMMAND_HELP: DB "HELP",0  ; null terminated strings
MON_COMMAND_DUMP: DB "DUMP",0
MON_COMMAND_SET: DB "SET",0
MON_COMMAND_LOAD: DB "LOAD",0
MON_COMMAND_RUN: DB "RUN",0
MON_COMMAND_ADB: DB "ADB",0
MON_ARG_HEX: DB "    0x",0
MON_HELP: DB 10,"Available commands:\nHELP prints this message\nDUMP shows memory content\nSET sets memory content LOAD\nRUN executes code\nADB starts Assembly Deploy Bridge",0
MON_MSG_ADB: DB 10,"Waiting for data.",0
MON_ERR_SYNTAX: DB "    Syntax error",0
;MON_ADB_TIMEOUT: EQU 0xFF     // Number of cycles after an ADB binary transfer is considered completed

Monitor_main:
    ; Print welcome string
    ld bc, MON_WELCOME
    call Print
    monitor_main_loop:
        ; Newline
        ld a, 10
        call Printc
        ; Draw prompt char
        ld a, 62 ; >
        call Printc
        ; Read char from command line
        call Readc     ; blocking: returns when a character was read and placed in A reg
        call Strings_charToUpper    ; user may enter lowercase char: transform to upper
        call Printc     ; Print back the character to provide user feedback
        ; Switch case
        ld hl, MON_COMMAND_HELP
        cp (hl)  ; check incoming char is equal to command's first char
        jp z, monitor_help
        ld hl, MON_COMMAND_DUMP
        cp (hl)
        jp z, monitor_dump
        ld hl, MON_COMMAND_SET
        cp (hl)
        jp z, monitor_set
        ld hl, MON_COMMAND_LOAD
        cp (hl)
        jp z, monitor_load
        ld hl, MON_COMMAND_RUN
        cp (hl)
        jp z, monitor_run
        ld hl, MON_COMMAND_ADB
        cp (hl)
        jp z, monitor_adb
        ; Unrecognized command: print error and beep
        ld bc, MON_ERR_SYNTAX
        call Print
        call Beep
    jp monitor_main_loop

monitor_help:
    ld bc, MON_COMMAND_HELP + 1 ; autocomplete command
    call Print

    ld bc, MON_HELP
    call Print
    jp monitor_main_loop

monitor_dump:
    ld bc, MON_COMMAND_DUMP + 1 ; autocomplete command
    call Print
    call monitor_arg_2byte  ; returns the read bytes in hl
    ld b, 64    ; the number of bytes to display
    monitor_dump_show_bytes_loop:
    ; print character at mem position
    ld a, (hl)
    call Printc
    ; move to next mem position
    inc hl
    ; decrement counter: if non zero continue loop
    dec b
    jp nz, monitor_dump_show_bytes_loop
    ; if counter 0, finished
    jp monitor_main_loop

monitor_set:
    ld bc, MON_COMMAND_SET + 1 ; autocomplete command
    call Print
    jp monitor_main_loop

monitor_load:
    ld bc, MON_COMMAND_LOAD + 1 ; autocomplete command
    call Print
    jp monitor_main_loop

monitor_run:
    ld bc, MON_COMMAND_RUN + 1 ; autocomplete command
    call Print
    jp APP_SPACE    ; Start executing code
    jp monitor_main_loop

monitor_adb:
    ld bc, MON_COMMAND_ADB + 1 ; autocomplete command
    call Print
    ; start copying incoming data to application space
    call monitor_copyTermToAppMem
    ;jp APP_SPACE    ; Start executing code
    ld bc, APP_SPACE
    call Print
    jp monitor_main_loop

; Prints "0x" and read 1 hex byte (2 hex digits, e.g. 0x8C)
; @return a the read byte
; @uses a, b, c
monitor_arg_byte:
    ; Print 0x... prompt
    ld bc, MON_ARG_HEX
    call Print
    ; Read 2 digits
    call monitor_arg_byte_impl
    ret

; Prints "0x" and reads 2 hex bytes (4 hex digits e.g. 0x3F09)
; @return hl the two read bytes
; @uses a, b, c, h, l
monitor_arg_2byte:
    ; Print 0x... prompt
    ld bc, MON_ARG_HEX
    call Print
    ; Read 2 digits
    call monitor_arg_byte_impl
    ld h, a ; move result to h
    ; Read 2 digits
    call monitor_arg_byte_impl
    ld l, a ; move result to l
    ret

; Read 2 hex digits
; @return a the read byte
; @uses a, b, c
monitor_arg_byte_impl:
    ; Receive first hex digit
    call monitor_readHexDigit
    ; First hex digit is the most signif nibble, so shift left by 4 bits
    sla a
    sla a
    sla a
    sla a
    ld c, a     ; save shifted nibble in c
    ; Read second hex digit
    call monitor_readHexDigit
    ; Join the two nibbles in a single byte: second digit is already in a,
    ; so we OR with the previously shifted c and obtain the complete byte in a.
    or c
    ld a, c ; store c in a for return
    ret

; Reads an hex digit (0 to 9, A to F)
; @return a the read nibble
; @uses a, b
monitor_readHexDigit:
    call Readc
    ; check if is a valid hex digit (0-9 -> ascii codes 48 to 57; A-F -> ascii codes 65 to 70)
    ; first check if is between 0 and F(ascii codes 48 to 70)
    ld b, a
    sub a, 48
    jp m, monitor_readHexDigit  ; if negative (s), ascii code is under 48: ignore char
    ld a, b
    sub a, 71   ; 71 because we want to include 70 and the result must be negative
    jp p, monitor_readHexDigit  ; if not negative (ns), ascii code is over 70: ignore it
    ; check if is a valid int (<=57)
    ld a, b
    sub a, 58
    jp p, monitor_readHexDigit_char  ; if not negative (ns), maybe is a char
    ; otherwise is a number! First print for visive feedback
    ld a, b
    call Printc
    ; then convert to its value subtracting 48
    sub a, 48
    ret
    monitor_readHexDigit_char:
    ; check if is A, B, C, D, E, F (ascii codes 65 to 70). We already checked it is less than 70.
    ld a, b
    sub a, 65
    jp m, monitor_readHexDigit  ; if negative (s), ascii code is under 65: ignore char
    ; otherwise is a valid char (A-F). Print for visive feedback
    ld a, b
    call Printc
    ; Its numeric value is 10 (A) to 15 (F). To obtain this, subtract 55.
    sub a, 55
    ret

; Copy data from STDIN to application memory. This is tought to be used with parallel terminal, not keyboard:
; 0s are not ignored and the sequence is complete when no data is available for 8 cpu cycles.
monitor_copyTermToAppMem:
    ld hl, APP_SPACE    ; we will write in APP_SPACE
    ld b, 255; MON_ADB_TIMEOUT     ; the timeout counter (number cycles without available data that represent the end of stream)
    monitor_copyTermToAppMem_loop:
    dec b   ; decrement the timeout counter
    ret 0   ; if counter is 0, timeout reached: return
    ; check if bytes are available
    call Term_availb
    cp 0
    jp z, monitor_copyTermToAppMem     ; no bytes available, next loop
    ; bytes are available
    ld b, 255 ;MON_ADB_TIMEOUT; reset the counter
    ld (hl), a  ; copy byte to memory
    inc hl  ; move to next memory position
    jp monitor_copyTermToAppMem_loop   ; continue loop


