; Source:  
; https://cowlark.com/2018-05-26-bogomandel/index.html#fixed-point-and-multiplication
;
;
; Once zr, zi, cr, ci have been set up, use reenigne's Mandelbrot kernel to
; calculate the colour.


    processor 6502
;mandel:
    PUSH_REGISTERS
    lda #GREEN
    sta COLUBK

    /*
    lda #3
    sta col
    lda #5
    sta row
*/
    lda #1
    sta iterations

    lda #0
    sta keepIterating

    lda #BLUE
    sta COLUBK
    POP_REGISTERS
    rts
mandel:
    ; push registers and state - save on stack
    PUSH_REGISTERS
    lda #ORANGE
    sta COLUBK

.cowlark_start:
    ldy #1              ; indexing with this accesses the high byte 

fixup_zr: 
    FIXUP zr
fixup_zi:
    FIXUP zi

    ; Calculate zr^2 + zi^2. 

    clc
    ldy #0
    lda (zr),y            ; A = low(zr^2)  
    tax
    adc (zi),y            ; A = low(zr^2) + low(zi^2) = low(zr^2 + zi^2) 
    sta zr2_p_zi2_lo
    ldy #1
    LDA (zr),y         ; A = high(zr^2) 
    adc (zi),y         ; A = high(zr^2) + high(zi^2) = high(zr^2 + zi^2) 
    ;cmp #4 << (fraction_bits-8)
    ;cmp #4 << 1    ;; FIXME:  1 is a placeholder
.compare
    ;   1111 0xxx x/xxx xxx0
    ;   1111 0100 x/xxxx xxx0
    cmp #$02
    bcs .bailoutToInfinityAndBeyond
    sta zr2_p_zi2_hi
    ;and #$07

    ; Calculate zr + zi. 

    ldy #0
    clc
    lda zr+0              ; A = low(zr) 
    adc zi+0              ; A = low(zr + zi) 
    sta zr_p_zi+0
    lda zr+1            ; A = high(zr) 
    adc zi+1            ; A = high(zr + zi) + C 
    and #$f7
    ora #$F0            ; fixup 
    sta zr_p_zi+1

    ; Calculate zr^2 - zi^2. 

    ldy #0
    txa
    sec
    sbc (zi),y            ; A = low(zr^2 - zi^2) 
    tax
    ldy #1
    lda (zr),y         ; A = high(zr^2) 
    sbc (zi),y         ; A = high(zr^2 - zi^2) 
    sta zr2_m_zi2+1

    ; Calculate zr = (zr^2 - zi^2) + cr. 

    clc
    txa
    adc cr+0              ; A = low(zr^2 - zi^2 + cr) 
    sta zr+0
    lda zr2_m_zi2+1     ; A = high(zr^2 - zi^2) 
    adc cr+1            ; A = high(zr^2 - zi^2 + cr) 
    and #$f7
    ora #$F0            ; fixup 
    sta zr+1

    ; Calculate zi' = (zr+zi)^2 - (zr^2 + zi^2). 

    sec
    ldy #0
    lda (zr_p_zi),y       ; A = low((zr + zi)^2) 
    sbc zr2_p_zi2_lo      ; A = low((zr + zi)^2 - (zr^2 + zi^2)) 
    tax
    ldy #1
    lda (zr_p_zi),y      ; A = high((zr + zi)^2) 
    sbc zr2_p_zi2_hi     ; A = high((zr + zi)^2 - (zr^2 + zi^2)) 
    tay

    ; Calculate zi = zi' + ci. 

    clc
    txa
    adc ci+0
    sta zi+0
    tya
    adc ci+1
    and #$f7
    ora #$F0            ; fixup 
    sta zi+1

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
 
    MAC fixup ; pass address of low byte of 16-bit int
    ;   example:  if passed a fixed point number to square
    ;   
    ;   input format:
    ;   xxxx0www wffffff0 
    ;   xxxx               dontcare
    ;       0              always 0
    ;        www w         whole portion
    ;             ffffff   fractional portion
    ;                   0  always 0
    ;   We will translate to 
    ;   11110www wffffff0
    ;   which is the address of the square of this number
    ; 
    ;   save cycles by assuming caller has set y to 1 :D
    ;
    PHA    

    lda {1}   ;low byte, we zero-out bit 0
    and #$FE
    sta {1}

    lda {1},Y  ; high byte, we turn on top 4 bits
    and #$f7
    ora #$f0
    sta {1},Y

    PLA
    ENDM
