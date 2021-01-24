; *******************************************
; *    PAT80 COMPOSITE PAL VIDEO ADAPTER    *
; *      Character generator module         *
; *******************************************

; This module generates the character pixels using the font present in rom
; and adds it on the framebuffer in the position indicated by POS_COARSE (Y).

.equ LINE_COLUMNS = 52	; number of columns (characters or chunks) per line

; Draws character in register A to the screen at current coords (Y)
; @param A (r0) ascii code to display
; @modifies r0 (A), r1, r2, r3, r16 (HIGH_ACCUM), Y, Z
draw_char:
	; Glyph's first byte is at:
	; glyph_pointer = font_starting_mem_pos + (ascii_code * number_of_bytes_per_font)
	; But all the fonts are 1 byte large, so a glyph is 1*height bytes:
	; glyph_pointer = FONT + (ascii_code * FONT_HEIGHT)

	; Save current chunk cursor position (Y)
	mov r2, YL
	mov r3, YH

	; Load first glyph position on Z
	ldi ZH, high(FONT)
	ldi ZL, low(FONT)
	; Obtain offset multiplying ascii_code * number_of_bytes_per_fontr1
	ldi HIGH_ACCUM, FONT_HEIGHT
	mul A, HIGH_ACCUM	; result overwrites r0 and r1!
	; 16-bit addition between gliph's first byte position and offset (and store result in Z)
	add ZL, A
	adc ZH, r1
	; Z contain our glyph's first byte position: draw it
	; The drawing consist of FONT_HEIGHT cycles. Every glyph byte is placed on its own line
	; on screen. To do this, we place it LINE_COLUMNS bytes after the previous one.
	ldi HIGH_ACCUM, FONT_HEIGHT
	draw_char_loop:
		; Load glyph line byte from program memory (and point to the next)
		lpm r1, Z+
		; Write glyph line to framebuffer at chunk cursor position (Y)
		st Y, r1
		; Increment chunk cursor position (Y) to next line of the same char column
		adiw YH:YL,LINE_COLUMNS
		; Decrement loop counter and exit if reached 0
		dec HIGH_ACCUM
		brne draw_char_loop
	; Char drawing is complete. Set chunk cursor position to next char first line
	mov YL, r2	; first restore Y
	mov YH, r3
	adiw YH:YL,1	; just increment pre-char-drawing-saved chunk cursor position by 1
	ret
