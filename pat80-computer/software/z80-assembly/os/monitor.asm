; Pat80 Memory Monitor
; @author Daniele Verducci
; @language: Z80 ASM
;
;
; This file is part of Pat80 Memory Monitor.
;
; Pat80 Memory Monitor is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; Pat80 Memory Monitor is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with Pat80 Memory Monitor.  If not, see <http://www.gnu.org/licenses/>.
;
;
; Monitor commands (CMD $arg):
;   H (HELP) Shows available commands
;   D (DUMP) $pos Dumps bytes of memory starting at $pos
;   S (SET) $pos $val Replaces byte at $pos with $val
;   L (LOAD) $pos $val
;   R (RUN) $pos Starts executing code from $pos
;   A (ADB) Enters in Assembly Depoy Bridge mode: loads all the incoming bytes in application memory and starts executing.
; The commands are entered with a single letter and the program completes the command

include 'libs/strings.asm'

; CONSTANTS
MON_WELCOME: DB 10,"PAT80 MEMORY MONITOR 0.2",10,0
MON_COMMAND_HELP: DB "HELP",0  ; null terminated strings
MON_COMMAND_DUMP: DB "DUMP",0
MON_COMMAND_SET: DB "SET",0
MON_COMMAND_ZERO: DB "ZERO",0
MON_COMMAND_LOAD: DB "LOAD",0
MON_COMMAND_RUN: DB "RUN",0
MON_COMMAND_ADB: DB "ADB",0
MON_COMMAND_MEMTEST: DB "MEMTEST",0
MON_COMMAND_QUIT: DB "QUIT",0
MON_ARG_HEX: DB "    0x",0
MON_HELP: DB 10,"Available commands:\nHELP prints this message\nDUMP [ADDR] shows memory content\nSET [ADDR] sets memory content\nZERO [ADDR] [ADDR] sets all bytes to 0 in the specified range\nLOAD\nRUN [ADDR] executes code starting from ADDR\nADB starts Assembly Deploy Bridge\nMEMTEST checks ram boundaries\nQUIT exits",0
MON_MSG_ADB: DB 10,"Waiting for data.",0
MON_ERR_SYNTAX: DB "    Syntax error",0
; MON_RAMTEST_INTRO: DB " Checking memory... ",0
; MON_RAMTEST_RAMSTART: DB " Ram starts at 0x",0
MON_DUMP_BYTES_LINES: EQU 8
MON_DUMP_BYTES_PER_LINE: EQU 8

Monitor_main:
    ; Print welcome string
    ld bc, MON_WELCOME
    call Sys_Print
    monitor_main_loop:
        ; Newline
        ld a, 10
        call Sys_Printc
        ; Draw prompt char
        ld a, 62 ; >
        call Sys_Printc
        ; Read char from command line
        call Sys_Readc     ; blocking: returns when a character was read and placed in A reg
        call Strings_charToUpper    ; user may enter lowercase char: transform to upper
        call Sys_Printc     ; Print back the character to provide user feedback
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
        ld hl, MON_COMMAND_ZERO
        cp (hl)
        jp z, monitor_zero
        ld hl, MON_COMMAND_LOAD
        cp (hl)
        jp z, monitor_load
        ld hl, MON_COMMAND_RUN
        cp (hl)
        jp z, monitor_run
        ld hl, MON_COMMAND_ADB
        cp (hl)
        jp z, monitor_adb
        ; ld hl, MON_COMMAND_MEMTEST
        ; cp (hl)
        ; jp z, monitor_memtest
        ld hl, MON_COMMAND_QUIT
		cp (hl)
		jp z, monitor_quit
        ; Unrecognized command: print error and beep
        ld bc, MON_ERR_SYNTAX
        call Sys_Print
        call Sys_Beep
    jp monitor_main_loop

monitor_help:
    ld bc, MON_COMMAND_HELP + 1 ; autocomplete command
    call Sys_Print

    ld bc, MON_HELP
    call Sys_Print
    jp monitor_main_loop

monitor_quit:
    ld bc, MON_COMMAND_QUIT + 1 ; autocomplete command
    call Sys_Print
	; newline
	ld a, 10
	call Sys_Printc
    ; Restores registers and re-enable interrupts: when the BREAK key is pressed, 
	; a maskable interrupt is generated and the CPU jumps to 0x38 reset vector, 
	; where if finds a call to Memory monitor (see main.asm).
	exx ; exchange registers
	ex af, af'
	; enable interrupts
	ei
	im 1 ; set interrupt mode 1 (on interrupt jumps to 0x38)
	reti ; return from interrupt


; Asks the user for a memory position and shows the following 64 bytes of memory
; @uses a, b, c, d, e, h, l
monitor_dump:
    ld bc, MON_COMMAND_DUMP + 1 ; autocomplete command
    call Sys_Print
    ; Now read the address from the user
    call monitor_arg_2byte  ; returns the read bytes in hl
    ld a, 10 ; newline
    call Sys_Printc
    ; now start displaying bytes from memory
    ld e, MON_DUMP_BYTES_LINES    ; the number of lines to display
    monitor_dump_show_bytes_loop:
        ld d, MON_DUMP_BYTES_PER_LINE*2   ; the number of bytes per line to display (*2 as we display two times the same byte: once hex and once ascii)
        ; Print current address
        ld a, h
        call monitor_printHexByte
        ld a, l
        call monitor_printHexByte
        ; print four spaces
        ld a, 32
        call Sys_Printc
        call Sys_Printc
        call Sys_Printc
        call Sys_Printc
        monitor_dump_show_bytes_line_loop:  ; counts down from 15 to 0
            ld a, d
            sub MON_DUMP_BYTES_PER_LINE + 1
            jp m, monitor_dump_show_bytes_line_loop_ascii   ; jp if
                ; if position is 8 to 15, print hex value at mem position
                ld a, (hl)
                ; print hex byte
                call monitor_printHexByte
                ; print space
                ld a, 32
                call Sys_Printc
                ; if position is 4, print a second space (to group nibbles)
                ld a, d
                cp MON_DUMP_BYTES_PER_LINE / 2 + MON_DUMP_BYTES_PER_LINE + 1
                jp nz, no_second_space
                    ; print second space
                    ld a, 32
                    call Sys_Printc
                no_second_space:
                ; move to next mem position
                inc hl
                ; decrement "nth byte on the line" counter
                dec d
                jp monitor_dump_show_bytes_line_loop
            ; if position is 0 to 7, print ascii
            monitor_dump_show_bytes_line_loop_ascii:
                ; is this the first ascii char printed in this line?
                ld a, d
                cp MON_DUMP_BYTES_PER_LINE
                jp nz, no_mempos_decr   ; no need to decrement, already done
                    ; do this only once: printing hex values we advanced the counter by 8 positions. Bring it back.
                    ld bc, MON_DUMP_BYTES_PER_LINE
                    sbc hl, bc
                    ; print 3 spaces to separate hex from ascii
                    ld a, 32
                    call Sys_Printc
                    call Sys_Printc
                    call Sys_Printc
                no_mempos_decr:
                ; print ascii
                ld a, (hl)
                call monitor_printAsciiByte
                ; print space
                ld a, 32
                call Sys_Printc
                ; if position is 12 (8+4), print a second space (to group nibbles)
                ld a, d
                cp MON_DUMP_BYTES_PER_LINE / 2 + 1
                jp nz, no_second_space2
                    ; print second space
                    ld a, 32
                    call Sys_Printc
                no_second_space2:
                ; move to next mem position
                inc hl
                ; decrement counter: if non zero continue loop
                dec d
                jp nz, monitor_dump_show_bytes_line_loop
        ; print newline
        ld a, 10
        call Sys_Printc
        ; decrement line counter
        dec e
        jp nz, monitor_dump_show_bytes_loop ; if line counter is not 0, print another line
    ; if line counter 0, finished
    jp monitor_main_loop

; Asks user for a memory position and a byte and puts the byte in memory
; @uses a, b, c, h, l
monitor_set:
    ld bc, MON_COMMAND_SET + 1 ; autocomplete command
    call Sys_Print
	; Now read the memory address to be changed from the user
    call monitor_arg_2byte  ; returns the read bytes in hl
	; Start looping memory addresses
	monitor_set_byte_loop:
		ld a, 10 ; newline
		call Sys_Printc
		; Print current address
        ld a, h
        call monitor_printHexByte
        ld a, l
        call monitor_printHexByte
        ; print two spaces
        ld a, 32
        call Sys_Printc
        call Sys_Printc
		; print previous memory content (hex)
		ld a, (hl)
		call monitor_printHexByte
		; print two spaces
        ld a, 32
        call Sys_Printc
        call Sys_Printc
		; print previous memory content (ascii)
		ld a, (hl)
		call monitor_printAsciiByte
		; print space
		ld a, 32
        call Sys_Printc
		; ask the user the new memory content
		call monitor_arg_byte	; returns the read byte in a, exit code in b
		; find if user pressed Q/ENTER
		ld c, a ; save a
		ld a, b ; exit code in a
		cp 1 ; check if user pressed Q
		jp z, monitor_main_loop	; user wants to exit
		ld a, b
		cp 2 ; check if user pressed ENTER
		jp z, monitor_set_skipbyte ; user doesn't want to replace current byte: skip
		; user didn't press Q/ENTER: he inserted a valid byte
		; print two spaces
        ld a, 32
        call Sys_Printc
        call Sys_Printc
		ld a, c ; restore valid byte in a
		call monitor_printAsciiByte ; print user-inserted byte in ascii
		ld a, c ; restore valid byte in a
		ld (hl), a ; write new byte to memory
		monitor_set_skipbyte:
		inc hl ; next memory position
	jp monitor_set_byte_loop

; Asks user for a memory range and sets all bytes to zero in that range in memory
; @uses a, b, c, h, l
monitor_zero: ; TODO: bugged, doesn't exit cycle
	ld bc, MON_COMMAND_ZERO + 1 ; autocomplete command
    call Sys_Print
	; Now read the starting memory address
    call monitor_arg_2byte  ; returns the read bytes in hl
	; starting addr in bc
	ld b, h
	ld c, l
	call monitor_arg_2byte  ; ending addr in hl	
	; Start looping memory addresses (from last to first)
	monitor_zero_loop:
		ld (hl), 0 ; set byte to 0 in memory
		dec hl	; next byte
		; check if we reached start addr (one byte at time)
		ld a, b
		cp h
		jp nz, monitor_zero_loop	; first byte is different, continue loop
		; first byte is equal, check second one
		ld a, c
		cp l
		jp nz, monitor_zero_loop	; second byte is different, continue loop
		; reached destination addr: zero the last byte and return
		ld (hl), 0 ; set byte to 0 in memory
		ret

monitor_load:
    ld bc, MON_COMMAND_LOAD + 1 ; autocomplete command
    call Sys_Print
	; TODO: When implemented, re-enable interrupts before run application
    jp monitor_main_loop

monitor_run:
    ld bc, MON_COMMAND_RUN + 1 ; autocomplete command
    call Sys_Print
    ; Now read the memory address to be executed from the user
    call monitor_arg_2byte  ; returns the read bytes in hl
    ld a, 10 ; newline
    call Sys_Printc	
	; enable interrupts
	ei
	im 1 ; set interrupt mode 1 (on interrupt jumps to 0x38)
	; pop the last entry on the stack: this is needed (as the monitor
	; runs in an interrupt) to counter-balance the missing reti statement
	pop bc
	; execute code
	jp (hl)

monitor_adb:
    ld bc, MON_COMMAND_ADB + 1 ; autocomplete command
    call Sys_Print
    ; start copying incoming data to application space
    call monitor_copyTermToAppMem
	; call monitor_enable_int    ; re-enable interrupts
    ;jp APP_SPACE    ; Start executing code


    ; ld bc, APP_SPACE
    ; call Sys_Print
    jp monitor_main_loop

; Prints "0x" and read 1 hex byte (2 hex digits, e.g. 0x8C)
; Can be cancelled with Q/ENTER
; @return a the read byte, b the exit code (0=valid byte in a, 1=Q, 2=ENTER)
; @uses a, b, c
monitor_arg_byte:
    ; Print 0x... prompt
    ld bc, MON_ARG_HEX
    call Sys_Print
    ; Read 2 digits
    call monitor_arg_byte_impl
    ret

; Prints "0x" and reads 2 hex bytes (4 hex digits e.g. 0x3F09)
; Ignores Q/ENTER keys
; @return hl the two read bytes
; @uses a, b, c, h, l
monitor_arg_2byte:
    ; Print 0x... prompt
    ld bc, MON_ARG_HEX
    call Sys_Print
    ; Read 2 digits
    call monitor_arg_byte_impl
    ld h, a ; move result to h
    ; Read 2 digits
    call monitor_arg_byte_impl
    ld l, a ; move result to l
    ret

; Read 2 hex digits
; @return a the read byte, b the exit code 
; (0 if no control key was, pressed, 1 for Q, 2 for RETURN)
; @uses a, b, c
monitor_arg_byte_impl:
    ; Receive first hex digit. Value in a, exit code in b
    call monitor_readHexDigit
	; check exit code to find if user pressed esc or return
	ld c, a ; save a
	ld a, b ; load exit code in a
	cp 0
	jp nz, monitor_arg_byte_impl_exitcode	; user pressed Q/RETURN key
	; user didn't press Q/RETURN: returned nibble is valid
	ld a, c ; restore a and discard c
    ; First hex digit is the most signif nibble, so rotate left by 4 bits
    rlca
    rlca
    rlca
    rlca
    ; the lower nibble must now be discarded
    and %11110000
    ld c, a     ; save shifted nibble in c
    ; Read second hex digit
    call monitor_readHexDigit
    ; Join the two nibbles in a single byte: second digit is already in a,
    ; so we OR with the previously shifted c and obtain the complete byte in a.
    or c
    ret

	monitor_arg_byte_impl_exitcode:
	; user pressed Q/RETURN key. Exit code is now in a.
	ld b, a	; move exit code in b
	ld a, 0 ; clear a
	ret



; Reads an hex digit (0 to 9, A to F)
; @return a the read nibble (or 0 if Q/RETURN was pressed), b the exit code 
; (0 if no control key was, pressed, 1 for Q, 2 for RETURN)
; @uses a, b
monitor_readHexDigit:
    call Sys_Readc
	; check if user pressed Q
	; if user pressed Q, return exit code 1 in b and 0 in a
	cp 81
	jp z, monitor_readHexDigit_esc
	; check if user pressed RETURN
	; if user pressed RETURN, return exit code 2 in b and 0 in a
	cp 10
	jp z, monitor_readHexDigit_return
	
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
    call Sys_Printc
    ; then convert to its value subtracting 48
    sub a, 48
	ld b, 0 ; set b to exit code 0 to represent "valid value in a"
    ret
    monitor_readHexDigit_char:
    ; check if is A, B, C, D, E, F (ascii codes 65 to 70). We already checked it is less than 70.
    ld a, b
    sub a, 65
    jp m, monitor_readHexDigit  ; if negative (s), ascii code is under 65: ignore char
    ; otherwise is a valid char (A-F). Print for visive feedback
    ld a, b
    call Sys_Printc
    ; Its numeric value is 10 (A) to 15 (F). To obtain this, subtract 55.
    sub a, 55
	ld b, 0 ; set b to exit code 0 to represent "valid value in a"
    ret

	monitor_readHexDigit_esc:
	ld a, 0
	ld b, 1
	ret
	monitor_readHexDigit_return:
	ld a, 0
	ld b, 2
	ret

; Prints a byte in hex format: splits it in two nibbles and prints the two hex digits
; NOTE: The byte in a will be modified!
; @param a the byte to print
; @uses a, b, c
monitor_printHexByte:
    ld c, a
    ; rotate out the least significant nibble to obtain a byte with the most significant nibble
    ; in the least significant nibble position
    rrca
    rrca
    rrca
    rrca
    ; the upper nibble must now be discarded
    and %00001111
	call monitor_printHexDigit
    ld a, c
	and %00001111   ; bitwise and: set to 0 the most significant nibble and preserve the least
    call monitor_printHexDigit
	ret

; Prints an hex digit
; @param a provides the byte containing, in the LSBs, the nibble to print
; @uses a, b
monitor_printHexDigit:
    ; check the input is valid (0 to 15)
    ld b, a
    sub 16  ; subtract 16 instead of 15 cause 0 is positive
    ; if positive, the input is invalid. Do not print anything.
    ret p
    ; now check if the digit is a letter (10 to 15 -> A to F)
    ld a, b ; restore a
    sub 10
    ; if a is positive, the digit is a letter
    jp p, monitor_printHexDigit_letter
	ld a, b	; restore a
    ; add 48 (the ASCII number for 0) to obtain the corresponding number
    add 48
	call Sys_Printc
    ret
    monitor_printHexDigit_letter:
	ld a, b	; restore a
    ; to obtain the corresponding letter we should subtract 10 (so we count from A)
    ; and add 65 (the ASCII number for A). So -10+65=+55 we add only 55.
    add 55
	call Sys_Printc
    ret

; Prints an ASCII character. Similar to system Print function, but
; ignores control characters and replaces any non-printable character with a dot.
; NOTE: the a register is modified
; @param a the byte to print
; @uses a, b
monitor_printAsciiByte:
    ld b, a ; save a (it will be modified)
    ; if < 32 is a control char, non printable
    sub 32
    jp m, monitor_printAsciiByte_nonprintable
    ld a, b ; restore a
    ; if >= 127 is an extended char, may not be printable
    sub 127
    jp p, monitor_printAsciiByte_nonprintable
    ; otherwise is a printable ascii char
    ld a, b ; restore a
    call Sys_Printc
    ret
    monitor_printAsciiByte_nonprintable:
    ld a, 46 ; print dot
    call Sys_Printc
    ret

; Copy data from parallel terminal to application memory. This is tought to be used with the ADB function of the Pat80 Python Terminal.
; Uses TERM_DATA_AVAIL_REG to check if a byte is available before reading it.
; The first two received bytes (heading bytes) defines the stream length (MSB first), the rest of the bytes are copied to memory.
; The copy is completed when the number of bytes defined in the heading bytes are received.
; @uses a, b, c, d, h, l
monitor_copyTermToAppMem:
    ; d contains the current status.
    ; 2 = waiting for first heading byte
    ; 1 = waiting for second heading byte
    ; 0 = heading bytes received, now receiving binary stream
    ld d, 2
    ld hl, APP_SPACE    ; we will write in APP_SPACE
    monitor_copyTermToAppMem_loop:
        ld a, d
        cp 2    ; check if we are receiving first header byte
        jp z, monitor_copyTermToAppMem_loop_rec_head_byte_1
        ld a, d
        cp 1    ; check if we are receiving second header byte
        jp z, monitor_copyTermToAppMem_loop_rec_head_byte_2
        ; we are receiving binary stream: read byte and save to memory
        call Term_readb ; reads a byte from terminal
        ld (hl), a  ; copy byte to memory
        inc hl  ; move to next memory position
        dec bc  ; decrement remaining bytes counter
        ; check if we reached the number of bytes to be transferred
        ld a, b
        cp 0
        jp nz, monitor_copyTermToAppMem_loop   ; continue loop
        ld a, c
        cp 0
        jp nz, monitor_copyTermToAppMem_loop   ; continue loop
        ; all bytes received, return
        ret

    monitor_copyTermToAppMem_loop_rec_head_byte_1:
        ; we are receiving first header byte: read byte and save to b
        call Term_readb ; reads a byte from terminal
        ld b, a
        dec d
        jp monitor_copyTermToAppMem_loop   ; continue loop
    monitor_copyTermToAppMem_loop_rec_head_byte_2:
        ; we are receiving second header byte: read byte and save to c
        call Term_readb ; reads a byte from terminal
        ld c, a
        dec d
        jp monitor_copyTermToAppMem_loop   ; continue loop

; Runs a memory test to identify ram memory boundaries and check the ram is working.
; Starting from last memory position, writes 0xFF, reads it back, writes 0x00, reads it back.
; Exits when the first value differs from the written value (this may be caused by a bad ram
; block or the start of rom in memory map). Prints the last good address on exit.
; monitor_memtest:
;  ld bc, MON_COMMAND_MEMTEST + 1 ; autocomplete command
;  call Sys_Print
; 	; Prints intro
;  ld bc, MON_RAMTEST_INTRO
;  call Sys_Print
; 	; Starts checking
; 	ld hl, MEM_END
; 	monitor_memtest_loop:
; 		; Save current byte value for later restore
;      ld c, (hl)
;      ; Write 0xFF
; 		ld a, 0xFF
; 		ld (hl), a
; 		; Read and compare 0xFF
; 		ld a, (hl)
; 		cp 0xFF
; 		jp nz, monitor_memtest_badram
; 		; Write 0x00
; 		ld a, 0x00
; 		ld (hl), a
; 		; Read and compare 0xFF
; 		ld a, (hl)
; 		cp 0x00
; 		jp nz, monitor_memtest_badram
; 		; Memory byte is good, restore previous value
;      ld (hl), c
;      ; Next one
; 		dec hl
; 		jp monitor_memtest_loop
; 	monitor_memtest_badram:
; 		; Found a bad memory byte (or entered rom block).
; 		ld bc, MON_RAMTEST_RAMSTART
; 		call Sys_Print
; 		; Print last valid memory addr
;      inc hl
;      ld a, h
;      call monitor_printHexByte
;      ld a, l
;      call monitor_printHexByte
;      ; Newline
;      ld a, 10
;      call Sys_Printc
;      ; Back to menu
; 		jp monitor_main_loop



