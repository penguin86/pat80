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

include "ps2_keyboard_scancodeset2.asm"    ; PS/2 Scan Codeset 2 mappings

; config (IO port 1)
PS2KEYB_CLEAR_REG: EQU IO_1
PS2KEYB_DATA_REG: EQU IO_1 + 1

PS2KEYB_BREAK: EQU 0xF0 - %10000000    ; The MSB is dropped: see NOTE on intro above

; Reads a single character. 0s are ignored (can be used with keyboard).
; Doesn't check DATA_AVAILABLE register of parallel port, because a 0 byte
; is ignored anyway (it represents the ASCII NUL control char).
; @return A The read character
PS2Keyb_readc:
    in a, (PS2KEYB_DATA_REG)    ; reads a character
    add a, 0
    jp z, Term_readc     ; if char is 0 (NULL), user didn't press any key: wait for character
	; check if code is a Break Code (0xF0). If it is, discard next key as it is a released key
	ld b, a    ; save a
	cp 0xF0    ; compare a with Break Code
	jp z, ps2keyb_readc_discard
	; we read a valid character: clean key registers
	in a, PS2KEYB_CLEAR_REG
	; TODO: Interpretare keycode con lo scan code set
	;ld a, b    ; restore a
    ret ; returns in the a register
	ps2keyb_readc_discard:
		; waits for next non-0 keycode and discards it
		; TODO
		jp PS2Keyb_readc    ; go back and wait for another keycode
