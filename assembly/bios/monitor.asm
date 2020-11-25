; Pat80 Memory Monitor
; @author Daniele Verducci
;
; Monitor commands (CMD $arg):
;   H (HELP) Shows available commands
;   D (DUMP) $pos Dumps first 100 bytes of memory starting at $pos
;   S (SET) $pos $val Replaces byte at $pos with $val
;   L (LOAD) $pos $val Loads all the incoming bytes in memory starting from $pos
;   R (RUN) $pos Starts executing code from $pos
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
MON_ARG_HEX: DB "0x",0
MON_HELP: DB 10,"Available commands: HELP, DUMP, SET, LOAD, RUN",0
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
        ; Unrecognized command: print error
        ld bc, MON_ERR_SYNTAX
        call Print
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
    jp APP_VAR_SPACE    ; Start executing code
    jp monitor_main_loop



