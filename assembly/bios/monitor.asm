; Pat80 Memory Monitor
; @author Daniele Verducci
;
; Monitor commands (CMD $arg):
;   H (HELP) Shows available commands
;   D (DUMP) $pos Dumps first 100 bytes of memory starting at $pos
;   S (SET) $pos $val Replaces byte at $pos with $val
;   L (LOAD) $pos $val
;   R (RUN) $pos Starts executing code from $pos
;   I (IMMEDIATE) Loads all the incoming bytes in application memory starting from $pos. When "0" is received 8 times starts executing the loaded code.
; The commands are entered with a single letter and the program completes the command

include 'libs/strings.asm'

; CONSTANTS
; All monitor commands are 3 chars long.
MON_WELCOME: DB "PAT80 MEMORY MONITOR 0.1",10,0
MON_COMMAND_HELP: DB "HELP",0  ; null terminated strings
MON_COMMAND_DUMP: DB "DUMP",0
MON_COMMAND_SET: DB "SET",0
MON_COMMAND_LOAD: DB "LOAD",0
MON_COMMAND_RUN: DB "RUN",0
MON_COMMAND_IMMEDIATE: DB "IMMEDIATE",0
MON_ARG_HEX: DB "    0x",0
MON_HELP: DB 10,"Available commands: HELP, DUMP, SET, LOAD, RUN",0
MON_MSG_IMMEDIATE: DB 10,"Waiting for data. 00000000 to execute.",0
MON_ERR_SYNTAX: DB "    Syntax error",0

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
        ld hl, MON_COMMAND_IMMEDIATE
        cp (hl)
        jp z, monitor_immediate
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
    call monitor_arg_byte
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

monitor_immediate:
    ld bc, MON_COMMAND_IMMEDIATE + 1 ; autocomplete command
    call Print
    ; start copying incoming data to application space
    call monitor_copyTermToAppMem
    jp APP_SPACE    ; Start executing code
    ;jp monitor_main_loop

; Read 1 hex byte (e.g. 0x8C)
monitor_arg_byte:
    ; Print 0x... prompt
    ld bc, MON_ARG_HEX
    call Print
    ; Receive two hex digits
    call monitor_readHexDigit
    call monitor_readHexDigit
    ret

; Reads 2 hex bytes (e.g. 0x3F09)
monitor_arg_2byte:
    ; Print 0x... prompt
    ld bc, MON_ARG_HEX
    call Print
    ; Receive four hex digits
    call monitor_readHexDigit
    call monitor_readHexDigit
    call monitor_readHexDigit
    call monitor_readHexDigit
    ret

; Reads an hex digit (0 to 9, A to F)
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
; 0s are not ignored and the sequence is complete when found 8 zeros.
monitor_copyTermToAppMem:
    call Term_readb
    cp 0
    jp z, monitor_copyTermToAppMem     ; wait for data stream to begin: ignore leading zeros
    ld hl, APP_SPACE    ; we will write in APP_SPACE
    ld b, 8     ; the number of zeros that represent the end of stream
    monitor_copyTermToAppMem_loop:
    ld (hl), a  ; copy byte to memory
    inc hl  ; move to next memory position
    cp 0    ; compare A to 0
    ; load next byte to A (this doesn't affect condition bits, so flag Z from previous cp is still valid)
    call Term_readb
    jp nz, monitor_copyTermToAppMem_loop   ; if during previous cp A was not 0, execute next cycle
    dec b   ; if A is 0, decrement "end of stream" counter
    ret z   ; if B is 0, we found 8 zeros, so the stream is finished: return.
    jp monitor_copyTermToAppMem_loop   ; otherwise, continue loop


