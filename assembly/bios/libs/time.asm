; Time library
; @author Daniele Verducci

; Duration (change these values based on CPU frequency)
TIME_DUR_SECOND: EQU 255

; Wait bc * 55 states
; Use 1 iteration as delay between I/O bus writes
; @param bc The number of iterations. Each iteration is 55 states long.
Time_delay55:
    bit     0,a    ; 8
    bit     0,a    ; 8
    bit     0,a    ; 8
    and     a,255  ; 7
    dec     bc      ; 6
    ld      a,c     ; 4
    or      a,b     ; 4
    jp      nz,Time_delay55   ; 10, total = 55 states/iteration
    ret