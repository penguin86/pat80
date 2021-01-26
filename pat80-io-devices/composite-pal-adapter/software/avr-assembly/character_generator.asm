; *******************************************
; *    PAT80 COMPOSITE PAL VIDEO ADAPTER    *
; *      Character generator module         *
; *******************************************

; This module generates the character pixels using the font present in rom
; and adds it on the framebuffer in the position indicated by POS_COARSE (Y).

.equ LINE_COLUMNS = 52	; number of columns (characters or chunks) per line

; Draws character in register A to the screen at current coords (Y)
; @param r16 (HIGH_ACCUM) ascii code to display
; @modifies r0 (A), r1, r2, r3, r16 (HIGH_ACCUM), r17, Y, Z
draw_char:
	; Glyph's first byte is at:
	; glyph_pointer = font_starting_mem_pos + (ascii_code * number_of_bytes_per_font)
	; But all the fonts are 1 byte large, so a glyph is 1*height bytes:
	; glyph_pointer = FONT + (ascii_code * FONT_HEIGHT)

	; Save current chunk cursor position (Y)
	mov r2, YL
	mov r3, YH

	; Load first glyph position on Z
	ldi ZH, high(FONT<<1)
	ldi ZL, low(FONT<<1)
	; Obtain offset multiplying ascii_code * number_of_bytes_per_font
	ldi r17, FONT_HEIGHT
	mul HIGH_ACCUM, r17	; result overwrites r0 and r1!
	; 16-bit addition between gliph's first byte position and offset (and store result in Z) to obtain our glyph position
	add ZL, r0
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

	; Char drawing is complete. Increment cursor position
	inc POS_COLUMN
	; Check if end of line
	cpi POS_COLUMN, 52
	breq draw_char_eol
	; Reset chunk position to first glyph line of next column
	mov YL, r2	; first restore Y
	mov YH, r3
	adiw YH:YL,1	; just increment pre-char-drawing-saved chunk cursor position by 1
	ret
	draw_char_eol:
		clr POS_COLUMN	; reset column to 0
		adiw YH:YL,1 ; increment chunk cursor position by 1 (begin of next line on screen)
		; Check if end of screen
		cpi YH, high(FRAMEBUFFER_END + 1)
		brne draw_char_end
		cpi YL, low(FRAMEBUFFER_END + 1)
		brne draw_char_end
		; End of screen reached! Scroll framebuffer by 1 line (=52*FONT_HEIGHT bytes)
		; TODO
	draw_char_end:
		ret

; Sets the cursor to 0,0 and clears fine position
cursor_pos_home:
	; Set all positions to 0
	clr POS_COLUMN
	clr POS_ROWP
	clr POS_FINE
	; Load framebuffer start position to Y
	ldi YH, high(FRAMEBUFFER)
	ldi YL, low(FRAMEBUFFER)
	; ldi YH, high(0x1000)
	; ldi YL, low(0x1000)
	ret

; Updates framebuffer pointer (Y) to point to current text cursor position (POS_COLUMN, POS_ROWP)
; Usage:
;    ldi POS_COLUMN, 55
;    ldi POS_ROWP, 13
;    call set_framebuffer_pointer_to_text_cursor ; (sets cursor to 4th character of second row in 13th row-pair = column 4, row 27 on screen)
; @modifies Y, R0, R1
set_framebuffer_pointer_to_text_cursor:
	; Load framebuffer start position to Y
	ldi YH, high(FRAMEBUFFER)
	ldi YL, low(FRAMEBUFFER)
	; Obtain offset between 0,0 and current cursor position
	mul POS_COLUMN, POS_ROWP	; result is in r1,r0
	; Sum offset to Y
	add YL, r0
	adc YH, r1
	ret



; Draws a newline
; Moves cursor to start of following screen line
; Takes care of particular cases, i.e. end of screen (shifts all screen up by one line)
draw_carriage_return:
	ret


