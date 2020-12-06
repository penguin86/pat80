SndTest_test:
    ; ch1 max volume
    ld a,%10010000
    out (SND_DATA_REG),a
    ; play note ch1
    ld a,%10000000
    out (SND_DATA_REG),a
    ld a,%00100000
    out (SND_DATA_REG),a
    ; wait
    ld bc, 1200
    call Time_delay55

    ; ch2 max volume
    ld a,%10110010
    out (SND_DATA_REG),a
    ; play note ch2
    ld a,%10100000
    out (SND_DATA_REG),a
    ld a,%00010000
    out (SND_DATA_REG),a
    ; wait
    ld bc, 1200
    call Time_delay55

    ; ch3 max volume
    ld a,%11010100
    out (SND_DATA_REG),a
    ; play note ch3
    ld a,%11000000
    out (SND_DATA_REG),a
    ld a,%00001000
    out (SND_DATA_REG),a
    ; wait
    ld bc, 2400
    call Time_delay55

    ; fade ch1,ch2,ch3
    ld d, 0 ; attenuation
    sndTest_fade:   ; BROKEN!
        inc d
        ; update ch1 atten
        ld a, d ; use A as attenuation
        and %10010000; place channel number in upper bits to compose attenuation byte
        out (SND_DATA_REG),a
        ; update ch2 atten
        ld a, d ; use A as attenuation
        and %10110010; place channel number in upper bits to compose attenuation byte
        out (SND_DATA_REG),a
        ; update ch3 atten
        ld a, d ; use A as attenuation
        and %11010100; place channel number in upper bits to compose attenuation byte
        out (SND_DATA_REG),a
        ; wait
        ld bc, 100
        call Time_delay55
        ; cycle until attenuation is 1111
        cp d %1111
        jp nz, sndTest_fade

    ; wait
    ld bc, 2400
    call Time_delay55

    ; play noise

    ret