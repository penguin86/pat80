; *******************************************
; *    PAT80 COMPOSITE PAL VIDEO ADAPTER    *
; *      Character generator module         *
; *******************************************

; This module generates the character pixels using the font present in rom
; and adds it on the framebuffer in the position indicated by POS_COARSE (Y).

.equ LINE_COLUMNS = 46	; number of columns (characters or chunks) per line

; Draws character in register A to the screen at current coords (Y)
; @param (HIGH_ACCUM) ascii code to display
; @modifies r0 (A), r1, r2, r3, r17, HIGH_ACCUM, Y, Z
draw_char:
	; Check char is valid
	cpi HIGH_ACCUM, 0x7f
	brlo draw_char_valid
	ret

	draw_char_valid:
	; Glyph's first byte is at:
	; glyph_pointer = font_starting_mem_pos + (ascii_code * number_of_bytes_per_font)
	; But all the fonts are 1 byte large, so a glyph is 1*height bytes:
	; glyph_pointer = FONT + (ascii_code * FONT_HEIGHT)

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
	; Obtain drawing position in framebuffer memory (in Y)
	call update_mem_pointer
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
	cpi POS_COLUMN, LINE_COLUMNS
	brsh draw_char_eol
	ret
	draw_char_eol:
		; end of line
		clr POS_COLUMN	; reset column to 0
		; Move cursor to next line
		ldi HIGH_ACCUM, FONT_HEIGHT
		add POS_ROWP, HIGH_ACCUM
		; check if reached end of screen
		cpi POS_ROWP, SCREEN_HEIGHT
		brsh draw_char_eos
		ret
	draw_char_eos:
		; end of screen: scroll screen but leave line pointer to last line
		call scroll_screen
		ret

; Sets the cursor to 0,0 and clears fine position
cursor_pos_home:
	; Set all positions to 0
	clr POS_COLUMN
	clr POS_ROWP
	ret

; Draws a newline
; Moves cursor to start of following screen line
; Takes care of particular cases, i.e. end of screen (shifts all screen up by one line)
draw_carriage_return:
	; Move cursor to line start
	ldi POS_COLUMN, 0
	; Move cursor to next line
	ldi HIGH_ACCUM, FONT_HEIGHT
	add POS_ROWP, HIGH_ACCUM
	; Check if end of screen
	cpi POS_ROWP, SCREEN_HEIGHT
	brsh draw_carriage_return_eos
	ret
	draw_carriage_return_eos:
	call scroll_screen
	ret

; Scrolls the screen by one line (=LINE_COLUMNS*FONT_HEIGHT bytes)
; and clears the last line (FRAMEBUFFER_END - LINE_COLUMNS*FONT_HEIGHT bytes)
; @uses A, Z
scroll_screen:
	; "Read" Pointer to first char of second line
	ldi YH, high(FRAMEBUFFER+(LINE_COLUMNS*FONT_HEIGHT))
	ldi YL, low(FRAMEBUFFER+(LINE_COLUMNS*FONT_HEIGHT))
	; "Write" Pointer to first char of first line
	ldi ZH, high(FRAMEBUFFER)
	ldi ZL, low(FRAMEBUFFER)
	; Copy data
	scroll_screen_copy_loop:
		ld A, Y+
		st Z+, A
		cpi YH, high(FRAMEBUFFER_END)
		brne scroll_screen_copy_loop
		cpi YL, low(FRAMEBUFFER_END)
		brne scroll_screen_copy_loop
	; All the lines have been "shifted" up by one line.
	; The first line is lost and the last is duplicate. Clear the last.
	clr A
	scroll_screen_clear_loop:
		st Z+, A
		cpi r31, high(FRAMEBUFFER_END)
		brne scroll_screen_clear_loop
		cpi r30, low(FRAMEBUFFER_END)
		brne scroll_screen_clear_loop
	; Last line cleared. Set cursor position
	clr POS_COLUMN	; cursor to first column
	ldi POS_ROWP, SCREEN_HEIGHT-FONT_HEIGHT
	ret

; Sets the Y register to point to the cursor's first line memory position
; The cursor's position is represented by registers POS_COLUMN and POS_ROWP
update_mem_pointer:
	; Compute memory pointer offset: offset = (LINE_COLUMNS*POS_ROWP)+POS_COLUMN
	; LINE_COLUMNS*POS_ROWP
	ldi HIGH_ACCUM, LINE_COLUMNS
	mul HIGH_ACCUM, POS_ROWP	; result overwrites r0 and r1!
	; ...+POS_COLUMN
	add r0, POS_COLUMN
	clr HIGH_ACCUM
	adc r1, HIGH_ACCUM
	; Set pointer to start of framebuffer
	ldi YL, low(FRAMEBUFFER)
	ldi YH, high(FRAMEBUFFER)
	; Add offset to pointer
	add YL, r0
	adc YH, r1
	ret

clear_screen:
	ldi YH, high(FRAMEBUFFER)
	ldi YL, low(FRAMEBUFFER)
	load_mem_loop:
		clr HIGH_ACCUM
		;ser HIGH_ACCUM
		st Y+, HIGH_ACCUM
		; if reached the last framebuffer byte, exit cycle
		cpi YH, high(FRAMEBUFFER_END)
		brne load_mem_loop	; if not 0, repeat h_picture_loop
		cpi YL, low(FRAMEBUFFER_END)
		brne load_mem_loop	; if not 0, repeat h_picture_loop
	ret