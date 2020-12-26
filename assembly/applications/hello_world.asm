; Prints "Hello world" in terminal
; Usage: assemble this file with z80asm and insert the resulting bytes
; via Memory Monitor from address 0xA000 to test SET and RUN commands.

org 0xA000  ; Set starting position to ram
ld bc, HELLO_WORLD_STR
Term_print:
    ld a, (bc)  ; bc is the pointer to string's first char
    cp 0        ; compare A content with 0 (subtract 0 from value and set zero flag Z if result is 0)
    jp z, term_print_end
    out (0x00),a    ; output char to IO device 0, addr 0
    inc bc ; increment bc to move to next char
    jp Term_print
	term_print_end:
	halt
HELLO_WORLD_STR: DB "Hello world!",0