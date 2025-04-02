; Source:  
; https://cowlark.com/2018-05-26-bogomandel/index.html#fixed-point-and-multiplication
;
;
; Once zr, zi, cr, ci have been set up, use reenigne's Mandelbrot kernel to
; calculate the colour.


    processor 6502
mandel:
    ; push registers and state - save on stack
    PUSH_REGISTERS

    lda #GREEN
    sta COLUBK
    lda #ITERATIONS              ; hack - one iteration at a time for easier time slicing
    sta iterations
iterator_loop:
    ldy #1              ; indexing with this accesses the high byte 

    ; Calculate zr^2 + zi^2. 

    clc
    lda zr            ; A = low(zr^2) 
    tax                 
    adc zi            ; A = low(zr^2) + low(zi^2) = low(zr^2 + zi^2) 
    sta zr2_p_zi2_lo
    lda zr, y         ; A = high(zr^2) 
    adc zi, y         ; A = high(zr^2) + high(zi^2) = high(zr^2 + zi^2) 
    ;cmp #4 << (fraction_bits-8)
    ;cmp #4 << 1    ;; FIXME:  1 is a placeholder
    bcs .bailoutToInfinityAndBeyond
    sta zr2_p_zi2_hi

    ; Calculate zr + zi. 

    clc
    lda zr+0            ; A = low(zr) 
    adc zi+0            ; A = low(zr + zi) 
    sta zr_p_zi+0
    lda zr+1            ; A = high(zr) 
    adc zi+1            ; A = high(zr + zi) + C 
    and #$3F
    ora #$80            ; fixup 
    sta zr_p_zi+1

    ; Calculate zr^2 - zi^2. 

    txa                 ; A = low(zr^2) 
    sec
    sbc zi            ; A = low(zr^2 - zi^2) 
    tax
    lda zr, y         ; A = high(zr^2) 
    sbc zi, y         ; A = high(zr^2 - zi^2) 
    sta zr2_m_zi2+1 

    ; Calculate zr = (zr^2 - zi^2) + cr. 

    clc
    txa
    adc cr+0            ; A = low(zr^2 - zi^2 + cr) 
    sta zr+0
    lda zr2_m_zi2+1     ; A = high(zr^2 - zi^2) 
    adc cr+1            ; A = high(zr^2 - zi^2 + cr) 
    and #$3F
    ora #$80            ; fixup 
    sta zr+1

    ; Calculate zi' = (zr+zi)^2 - (zr^2 + zi^2). 

    sec
    lda zr_p_zi       ; A = low((zr + zi)^2) 
    sbc zr2_p_zi2+0     ; A = low((zr + zi)^2 - (zr^2 + zi^2)) 
    tax
    lda zr_p_zi, y    ; A = high((zr + zi)^2) 
    sbc zr2_p_zi2+1     ; A = high((zr + zi)^2 - (zr^2 + zi^2)) 
    tay

    ; Calculate zi = zi' + ci. 

    clc
    txa
    adc ci+0
    sta zi+0
    tya
    adc ci+1
    and #$3F
    ora #$80            ; fixup 
    sta zi+1

    dec iterations  
    bne .return   ;; or fall through if we've reached 0 iterations

.bailoutMaxIterations:
    ; we've reached the maximum number of iterations. This point is in the set.
    ; iterations contains the pixel colour
    lda #0
    sta keepIterating
    jmp .return


.bailoutToInfinityAndBeyond:
    ; |z^2| > 4, so we are out of the set.
    ; iterations contains the pixel colour
    lda #0
    sta keepIterating
    jmp .return

.return:
    PHA
    lda #BLUE
    sta COLUBK
    PLA

    ; restore saved registers and state from stack
    POP_REGISTERS
    rts
