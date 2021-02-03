; PS/2 Keycode Mode 2 to ASCII mapping table
;
; Keycodes 0 to 83

.db PS2KEYB_SCANCODESET_ASCII_MAP: .db 0	; (Unused)
.db 0	; F9
.db 0	; (Control key)
.db 0	; F5
.db 0	; F3
.db 0	; F1
.db 0	; F2
.db 0	; F12
.db 0	; (Control key)
.db 0	; F10
.db 0	; F8
.db 0	; F6
.db 0	; F4
.db 9	; TAB
.db 96	; `
.db 0	; (Unused)
.db 0	; (Unused)
.db 0	; L ALT
.db 0	; L SHFT
.db 0	; (Control key)
.db 0	; L CTRL
.db 1	; Q
.db 2	; 1
.db 0	; (Unused)
.db 0	; (Unused)
.db 0	; (Unused)
.db 3	; Z
.db 4	; S
.db 65	; A
.db 66	; W
.db 67	; 2
.db 0	; (Unused)
.db 0	; (Unused)
.db 68	; C
.db 69	; X
.db 70	; D
.db 71	; E
.db 72	; 4
.db 73	; 3
.db 0	; (Unused)
.db 0	; (Unused)
.db 32	; SPACE
.db 33	; V
.db 34	; F
.db 35	; T
.db 36	; R
.db 37	; 5
.db 0	; (Unused)
.db 0	; (Unused)
.db 38	; N
.db 39	; B
.db 40	; H
.db 41	; G
.db 42	; Y
.db 43	; 6
.db 0	; (Unused)
.db 0	; (Unused)
.db 0	; (Unused)
.db 44	; M
.db 45	; J
.db 46	; U
.db 47	; 7
.db 48	; 8
.db 0	; (Unused)
.db 0	; (Unused)
.db 44	; ,
.db 45	; K
.db 46	; I
.db 47	; O
.db 48	; 0
.db 49	; 9
.db 0	; (Unused)
.db 0	; (Unused)
.db 46	; .
.db 47	; /
.db 48	; L
.db 59	; ;
.db 60	; P
.db 45	; -
.db 0	; (Unused)
.db 0	; (Unused)
.db 0	; (Unused)
.db 39	; '
.db 0	; (Unused)
.db 91	; [
.db 61	; =
.db 0	; (Unused)
.db 0	; (Unused)
.db 0	; CAPS
.db 0	; R SHFT
.db 10	; ENTER
.db 93	; ]
.db 0	; (Unused)
.db 92	; \
.db 0	; (Unused)
.db 0	; (Unused)
.db 0	; (Unused)
.db 0	; (Unused)
.db 0	; (Unused)
.db 0	; (Unused)
.db 0	; (Unused)
.db 0	; (Unused)
.db 8	; BKSP
.db 0	; (Unused)
.db 0	; (Unused)
.db 9	; KP 1
.db 0	; (Unused)
.db 10	; KP 4 -- NOTE: shadowed by break code (see the NOTE in ps2_keyboard.asm)
.db 11	; KP 7
.db 0	; (Unused)
.db 0	; (Unused)
.db 0	; (Unused)
.db 48	; KP 0
.db 46	; KP .
.db 47	; KP 2
.db 48	; KP 5
.db 49	; KP 6
.db 50	; KP 8
.db 27	; ESC
.db 0	; NUM
.db 0	; F11
.db 43	; KP +
.db 44	; KP 3
; The following codes are unrecognized by PAT80, as it uses only 7 bits (see the NOTE in ps2_keyboard.asm)
; .db 45	; KP -
; .db 42	; KP *
; .db 43	; KP 9
; .db 0	; SCROLL
; .db 0	; (Control key)
; .db 0	; (Control key)
; .db 0	; (Control key)
; .db 0	; (Control key)
; .db 0	; F7