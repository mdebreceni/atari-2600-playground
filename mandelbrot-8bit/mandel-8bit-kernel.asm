; Source:  
; https://cowlark.com/2018-05-26-bogomandel/index.html#fixed-point-and-multiplication
;
;
; Once zr, zi, cr, ci have been set up, use reenigne's Mandelbrot kernel to
; calculate the colour.


    processor 6502

    INCLUDE "squares-8bit.asm"

mandel:
    ; push registers and state - save on stack
    PUSH_REGISTERS
    lda #ORANGE
    sta COLUBK
    ldy #1
    ; Calculate zr^2 + zi^2. 
    clc
    ldy zr
    lda squares,y            ; A = zr^2
    sta zr2
    tax
    ldy zi
    lda squares,y            ; A = low(zr^2) + low(zi^2) = low(zr^2 + zi^2) 
    sta zi2
    CLC
    adc zr2
    sta zr2_p_zi2
.compare
    ;   1111 0xxx x/xxx xxx0
    ;   1111 0100 x/xxxx xxx0
    cmp #$40
    bcs .bailoutToInfinityAndBeyond

    ; Calculate zr + zi. 
    clc
    lda zr              ; A = low(zr) 
    adc zi              ; A = low(zr + zi) 
    sta zr_p_zi
    
    ; Calculate zr^2 - zi^2. 
    txa   ; x has zr2 in it
    sec
    sbc zi2            ; A = (zr^2 - zi^2) 
    tax   ; x now has zr^2 - zi^2

    ; Calculate zr = (zr^2 - zi^2) + cr. 
    clc
    txa                 ; A = (zr^2 - zi^2)
    adc cr              ; A = (zr^2 - zi^2 + cr) 
    sta zr
    
    ; Calculate zi' = (zr+zi)^2 - (zr^2 + zi^2). 
    sec
    ldy zr_p_zi
    lda squares,y       ; A = ((zr + zi)^2) 
    sbc zr2_p_zi2         ; A = ((zr + zi)^2 - (zr^2 + zi^2)) 
    tax                   ; X = A

    ; Calculate zi = zi' + ci. 
    clc
    txa
    adc ci
    sta zi
    tya

.dec_iterations
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
 

