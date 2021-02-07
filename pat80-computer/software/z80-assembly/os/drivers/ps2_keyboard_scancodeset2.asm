; PS/2 Keycode Mode 2 to ASCII mapping table
;
; Keycodes 0 to 83

PS2KEYB_SCANCODESET_ASCII_MAP: DB 0	; (Unused)
DB 0	; F9
DB 0	; (Control key)
DB 0	; F5
DB 0	; F3
DB 0	; F1
DB 0	; F2
DB 0	; F12
DB 0	; (Control key)
DB 0	; F10
DB 0	; F8
DB 0	; F6
DB 0	; F4
DB 9	; TAB
DB 96	; `
DB 0	; (Unused)
DB 0	; (Unused)
DB 0	; L ALT
DB 0	; L SHFT
DB 0	; (Control key)
DB 0	; L CTRL
DB 1	; Q
DB 2	; 1
DB 0	; (Unused)
DB 0	; (Unused)
DB 0	; (Unused)
DB 3	; Z
DB 4	; S
DB 65	; A
DB 66	; W
DB 67	; 2
DB 0	; (Unused)
DB 0	; (Unused)
DB 68	; C
DB 69	; X
DB 70	; D
DB 71	; E
DB 72	; 4
DB 73	; 3
DB 0	; (Unused)
DB 0	; (Unused)
DB 32	; SPACE
DB 33	; V
DB 34	; F
DB 35	; T
DB 36	; R
DB 37	; 5
DB 0	; (Unused)
DB 0	; (Unused)
DB 38	; N
DB 39	; B
DB 40	; H
DB 41	; G
DB 42	; Y
DB 43	; 6
DB 0	; (Unused)
DB 0	; (Unused)
DB 0	; (Unused)
DB 44	; M
DB 45	; J
DB 46	; U
DB 47	; 7
DB 48	; 8
DB 0	; (Unused)
DB 0	; (Unused)
DB 44	; ,
DB 45	; K
DB 46	; I
DB 47	; O
DB 48	; 0
DB 49	; 9
DB 0	; (Unused)
DB 0	; (Unused)
DB 46	; .
DB 47	; /
DB 48	; L
DB 59	; ;
DB 60	; P
DB 45	; -
DB 0	; (Unused)
DB 0	; (Unused)
DB 0	; (Unused)
DB 39	; '
DB 0	; (Unused)
DB 91	; [
DB 61	; =
DB 0	; (Unused)
DB 0	; (Unused)
DB 0	; CAPS
DB 0	; R SHFT
DB 10	; ENTER
DB 93	; ]
DB 0	; (Unused)
DB 92	; \
DB 0	; (Unused)
DB 0	; (Unused)
DB 0	; (Unused)
DB 0	; (Unused)
DB 0	; (Unused)
DB 0	; (Unused)
DB 0	; (Unused)
DB 0	; (Unused)
DB 8	; BKSP
DB 0	; (Unused)
DB 0	; (Unused)
DB 9	; KP 1
DB 0	; (Unused)
DB 10	; KP 4 -- NOTE: shadowed by break code (see the NOTE in ps2_keyboard.asm)
DB 11	; KP 7
DB 0	; (Unused)
DB 0	; (Unused)
DB 0	; (Unused)
DB 48	; KP 0
DB 46	; KP .
DB 47	; KP 2
DB 48	; KP 5
DB 49	; KP 6
DB 50	; KP 8
DB 27	; ESC
DB 0	; NUM
DB 0	; F11
DB 43	; KP +
DB 44	; KP 3
; The following codes are unrecognized by PAT80, as it uses only 7 bits (see the NOTE in ps2_keyboard.asm)
; DB 45	; KP -
; DB 42	; KP *
; DB 43	; KP 9
; DB 0	; SCROLL
; DB 0	; (Control key)
; DB 0	; (Control key)
; DB 0	; (Control key)
; DB 0	; (Control key)
; DB 0	; F7