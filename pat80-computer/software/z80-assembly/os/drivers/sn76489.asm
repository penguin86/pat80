; TI SN76489 sound chip driver
; @author Daniele Verducci
; @language: Z80 ASM
;
;
; This file is part of Pat80 Memory Monitor.
;
; Pat80 Memory Monitor is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; Pat80 Memory Monitor is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with Pat80 Memory Monitor.  If not, see <http://www.gnu.org/licenses/>.
;
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
    ld bc, (TIME_DUR_MILLIS * 10)
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
    
