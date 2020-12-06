; TI SN76489 sound chip display driver
; @author Daniele Verducci
;
; USAGE:
; call Snd_init                     <-- inits sound (and silences default tone)
; call Snd_beep                     <-- system beep

; Sound card is on port 1
SND_DATA_REG: EQU IO_1

; Init device (silence all channels)
; Bits meaning:
; 1 R0 R1 R2 A0 A1 A2 A3
;   Bit0 is 1
;   Bit1,2,3 select the channel: 001, 011, 101, 111(noise)
;   Bit4,5,6,7 selecy the attenuation (0000=full volume, 1111=silent)
Snd_init:
    ; silence ch1
    ld a,%10011111
    out (SND_DATA_REG),a
    ; silence ch2
    ld a,%10111111
    out (SND_DATA_REG),a
    ; silence ch3
    ld a,%11011111
    out (SND_DATA_REG),a
    ; silence noise ch
    ld a,%11111111
    out (SND_DATA_REG),a
    ret

; Plays the system beep.
Snd_beep:
    ; ch1 max volume
    ld a,%10010000
    out (SND_DATA_REG),a
    ; play beep freq
    ld a,%10000000
    out (SND_DATA_REG),a
    ld a,%00001000
    out (SND_DATA_REG),a
    ; wait
    ld bc, (TIME_DUR_MILLIS * 150)
    call Time_delay55
    ; silence ch1
    ld a,%10011111
    out (SND_DATA_REG),a
    ret

; Sets the attenuation value for a channel
; @param a Channel (0, 1, 2, 3(Noise))
; @param c Attenuation (0 to 16)
; Snd_setAtt:
;     cp a, 0
    
