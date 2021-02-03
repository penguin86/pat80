; PS/2 Keyboard driver
;
; Based on PS/2 protocol as documented on http://www.lucadavidian.com/2017/11/15/interfacing-ps2-keyboard-to-a-microcontroller/
;
; The CLK and Data pin of the PS/2 keyboard are fed into two cascated serial-in parallel-out shift registers.
; Their outputs are connected to the Pat80 data bus via a buffer activated by the selected 
; I/O EN signal and their RESET is connected to I/O Address line 0 of the keyboard I/O port. 
; Being RESET active low, they will be erased when the PAT80 reads (or writes) anything at address 0 
; of the keyboard I/0 port.
;
; Thus, the read cycle is:
; - Read address 1 of the I/O port (the data bus will contain read keycode)
; - Read address 0 of the I/O port (the shift registers will be reset)
; The read keycode must be interpreted based on PS/2 Scan Codeset 2
;
; NOTE: The keyboard controller circuit throws away the MSB (uses only the lower 7 bits), because this allows
; for using a single buffer chip instead of two (the freed up line is used by the PAT80 to reset the shift
; registers). This means that the few keys with keycodes > 0x0F are not readable and that the break code is
; seen by PAT80 not as 0xF0, but 0x70. This also means that the 0 of numeric keypad on extended keyboards will
; behave strangely (will drop next pressed key). This is not a problem, as the computer, once completed, will
; have a 60% keyboard, without any of the unusable keys.

include 'ps2_keyboard_scancodeset2.asm'    ; PS/2 Scan Codeset 2 mappings

; config (IO port 1)
PS2KEYB_CLEAR_REG: EQU IO_2
PS2KEYB_DATA_REG: EQU IO_2 + 1

PS2KEYB_TRANSMISSION_DURATION: EQU 86 ;@ 100khz    ; The time needed for the keyboard to transmit all the 11 bits of data, in CPU clock cycles

PS2KEYB_BREAK: EQU 0xF0 - %10000000    ; The MSB is dropped: see NOTE on intro above

; Reads a single character and returns an ascii code when a valid key is pressed. Blocking.
; @return A The read character
PS2Keyb_readc:
    in a, (PS2KEYB_DATA_REG)    ; reads a character
    add a, 0
    jp z, Term_readc     ; if char is 0 (NULL), user didn't press any key: wait for character
	; we found something, allow the keyboard to complete data transmission
	ld a, PS2KEYB_TRANSMISSION_DURATION/5    ; every cycle is 5 CPU cycles
	ps2keyb_readc_waitloop:
		sub 1
		jr nz, ps2keyb_readc_waitloop
	; data transmission should now be complete.
	; check if code is a Break Code. If it is, discard next key as it is a released key
	ld c, a    ; save a
	cp PS2KEYB_BREAK    ; compare a with Break Code
	jp z, ps2keyb_readc_discard    ; if it is a Break Code, jump to discarder routine
	; we read a valid character: clean key registers
	in a, PS2KEYB_CLEAR_REG
	; now we will convert keycode in c to ASCII code
	ld hl, PS2KEYB_SCANCODESET_ASCII_MAP    ; load start of codeset to ascii map
	ld b, 0    ; reset b, as we are going to do a sum with bc (where c contains the read scancode)
	add hl, bc    ; add scancode value to map start addr (we are using it as offset)
	ld a, (hl)    ; load the corresponding ascii code in a for return
    ret ; returns in the a register
	ps2keyb_readc_discard:
		; clean key registers
		in a, PS2KEYB_CLEAR_REG
		ps2keyb_readc_discard_waitfordata:
			; wait for next non-0 keycode and discards it (it is the code of the released key)
			in a, (PS2KEYB_DATA_REG)    ; reads a character
			add a, 0
			jp z, ps2keyb_readc_discard_waitfordata     ; if char is 0 (NULL), wait
			; we found something, allow the keyboard to complete data transmission
			ld a, PS2KEYB_TRANSMISSION_DURATION/5    ; every cycle is 5 CPU cycles
			ps2keyb_readc_discard_waitloop:
				sub 1
				jr nz, ps2keyb_readc_discard_waitloop
			; data transmission should now be complete, throw away key code
			in a, PS2KEYB_CLEAR_REG
	jp PS2Keyb_readc    ; go back and wait for another keycode
