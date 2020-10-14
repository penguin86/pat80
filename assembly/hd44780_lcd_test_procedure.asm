;hd44780 lcd test procedure

ld hl,$4000     ;address reg points to lcd instruction address

;reset procedure
ld a,%00111000
ld (hl),a
ld a,%00001000
ld (hl),a
ld a,%00000001
ld (hl),a

;init procedure
ld a,%00111000
ld (hl),a
ld a,%00001110
ld (hl),a

;write characters to display
ld hl,$4001     ;address reg points to lcd data address

ld a,%01000100
ld (hl),a
ld a,%01100001
ld (hl),a
ld a,%01101110
ld (hl),a
ld a,%01101001
ld (hl),a
ld a,%01100101
ld (hl),a
ld a,%01101100
ld (hl),a
ld a,%01100101
ld (hl),a
ld a,%00100001
ld (hl),a

halt

