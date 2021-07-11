; Time library
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


; Duration in cpu cycles / 55 (change these values based on CPU frequency)
TIME_DUR_SECOND: EQU 1818
TIME_DUR_MILLIS: EQU 2

; Wait bc * 55 states
; Use 1 iteration as delay between I/O bus writes
; @param bc The number of iterations. Each iteration is 55 states long.
Time_delay55:
ret
    bit     0,a    ; 8
    bit     0,a    ; 8
    bit     0,a    ; 8
    and     255  ; 7
    dec     bc      ; 6
    ld      a,c     ; 4
    or      b     ; 4
    jp      nz,Time_delay55   ; 10, total = 55 states/iteration
    ret