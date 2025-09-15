; Stable screen for rendering Mandelbrot
; Based on 8blit - S01E02 Generating a stable screen
;
; Become a Patron - https://patreon.com/8blit
; 8blit Merch - https://8blit.myspreadshop.com/
; Subscribe to 8Blit - https://www.youtube.com/8blit?sub_confirmation=1
; Follow on Facebook - https://www.facebook.com/8Blit
; Follow on Instagram - https://www.instagram.com/8blit
; Visit the Website - https://www.8blit.com 

	processor 6502
	include "vcs.h"
MAX_ITERATIONS = 120
rows = 32  ; number of rows to render (two playfield bytes per row)
cols = 16  ; number of columns to render (half of a mirrored playfield using PF1 and PF2- 16 bits)
mandelByteCount = 2 * rows
scanlines_per_row = 5
tim64_clocks_per_row = 7


TASK_IDLE      = $00
TASK_ITERATE   = $01
TASK_UPDATEPF  = $02
TASK_SETUP_NEXT_ITERATION = $03

BLUE           = $9a         ;              define symbol for TIA color (NTSC)
ORANGE         = $2c
GREEN          = $ca


    SEG.U variables
    ORG $80

mandelBytes  ds mandelByteCount

zr  ds.b 1
zi  ds.b 1
cr  ds.b 1
ci  ds.b 1
;// y   ds.w 1

zr_p_zi ds.b 1
zr2_p_zi2 ds.b 1
zr2_m_zi2 ds.b 1
zi2 ds.b 1
zr2 ds.b 1

; starting points for Cr / Ci
crStart ds.b 1 ;
ciStart ds.b 1 ; 


cStep ds.b   1 ; increment between iterations (both c real and c imaginary)

iterations ds.b 1     ; number of remaining iterations

keepIterating ds.b 1  ; have we reached a final result yet?
activeTask ds.b 1           ; active task

row ds.b 1            ; current column being rendered (0 .. rows)
col ds.b 1            ; current column (0..15)   (columns 0..7 are in PF1, 8-15 are in PF2)
pfBitMask ds.b 1          ; bit number of playfield to turn on

;==============

    SEG CODE
    ORG $f000
    include "mandel-8bit-kernel.asm"

pf1SetBitMask dc.b $80, $40, $20, $10, $08, $04, $02, $01
pf2SetBitMask dc.b $01, $02, $04, $08, $10, $20, $40, $80

reset:
	; clear RAM and all TIA registers
	ldx #0                   ;              load the value 0 into (x)
	lda #0                   ;              load the value 0 into (a)
clear:                       ;              define a label 
	sta 0,x                  ;              store value in (a) at address of 0 with offset (x)
	inx                      ;              inc (x) by 1. it will count to 255 then rollover to 0
	bne clear                ;              branch up to the 'clear' label if (x) != 0

init:
    lda #03
    sta CTRLPF
    ldy #0
    lda #0
initMandelBytes:
    ; ora #$f0
    lda #0
    sta mandelBytes,y
    iny
    tya
    cpy #mandelByteCount
    bne initMandelBytes

    jsr initMandelVars
    lda #TASK_ITERATE
    sta activeTask


startFrame:
	; start of new frame
	; start of vertical blank processing
	lda #0                   ;              load the value 0 into (a)
	sta VBLANK               ;              store (a) into the TIA VBLANK register
	lda #2                   ;              load the value 2 into (a). 
	sta VSYNC                ;              store (a) into TIA VSYNC register to turn on vsync
	sta WSYNC                ;              write any value to TIA WSYNC register to wait for hsync
	lda #BLUE                ;              load the value from the symbol 'blue' into (a)
	sta COLUBK               ;              store (a) into the TIA background color register
;---------------------------------------
	sta WSYNC
;---------------------------------------
	sta WSYNC                ;              we need 3 scanlines of VSYNC for a stable frame
;---------------------------------------
	lda #0
	sta VSYNC                ;              store 0 into TIA VSYNC register to turn off vsync

	; generate 37 scanlines of vertical blank
	ldx #0
verticalBlank:   
	sta WSYNC                ;              write any value to TIA WSYNC register to wait for hsync
;---------------------------------------
	inx
	cpx #37                  ;              compare the value in (x) to the immeadiate value of 37
	bne verticalBlank        ;              branch to 'verticalBlank' label if compare not equal


    lda #BLUE
    sta COLUBK
	; generate 192 lines of playfield

startMandelBytes:
    ldx #0
    ldy #0
drawMandelBytes:
    lda #0
	sta WSYNC
    sta PF0
    lda mandelBytes,y
    sta PF1
    iny
    lda mandelBytes,y
    sta PF2
    iny

    lda #tim64_clocks_per_row
    sta TIM64T
    jsr runActiveTask
    
renderRowLoop:
    lda INTIM
    bne renderRowLoop    ; consume rest of INTIM timer
renderRowCountUp:
    lda #0
    sta WSYNC  ; wait for rest of line
    REPEAT scanlines_per_row ; count up more lines
    inx
    REPEND
    cpy #mandelByteCount
    bne drawMandelBytes

startFooter:
    lda #ORANGE
    sta COLUBK
    lda #0
    sta PF0
    sta PF1
    sta PF2
draw_footer:
    lda #0
    sta WSYNC
    inx 
    cpx #192
    bne draw_footer

startOverscan:
	; end of playfield - turn on vertical blank
    lda #%01000010
    sta VBLANK

	; generate 30 scanlines of overscan
	ldx #0
draw_overscan:        
	sta WSYNC
;---------------------------------------
	inx
	cpx #30                  ;              compare value in (x) to immeadiate value of 30
	bne draw_overscan        ;              branch up to 'draw_overscan' label, compare if not equal
	jmp startFrame           ;              frame completed, branch up to the 'startFrame' label
;------------------------------------------------

updatePfBits:
    PUSH_REGISTERS

    lda row
    asl              ; row * 2 -> address for PF1 bit - we will then transfer this to y
    tay              ; y should index to PF1 mandelbyte for current row (PF1)

    lda col          ; which bit are we updating?
    cmp #8
    bcs .updatePF2    ; equal or greater than 8 -> we are in PF2
.updatePF1:          ; PF1:  col 01234567 --> bit 76543210
    ; col 0 -> bit 7, col 1 -> bit 6, etc
    ldx col
    ; SEC
    ; sbc col          ; 7 - col -> bit number to flip.  We'll put this in X, since Y is taken
    ; tax            
    lda pf1SetBitMask,x  ; look up a bit mask that enables the selected bit
    sta pfBitMask
.setOrClearPF1
    lda iterations
    ;and #01
    cmp #0
    beq .clearBitPF1
.setBitPF1
    lda pfBitMask          ; should have only 1 bit set
    ora mandelBytes,Y
    sta mandelBytes,Y
    jmp .bailOutUpdateBits
.clearBitPF1
    ;lda pfBitMask          ; should start with only 1 bit set
    ; eor #$FF           ; invert all bits
    ; and mandelBytes,Y  ; clear only the bit that is off
    ; sta mandelBytes,Y
    ; jmp .bailOutUpdateBits

.updatePF2:          ;  PF2:   col 89abcdef --> bit 01234567
    iny               ; we want the mandelByte after PF1 for this row
    SEC
    sbc #8            ; gives bit offset in PF2 (from leftmost displayed bit)
                      ; PF2 bits are in opposite direction of PF1
                      ; col 8 -> bit 0, col 9 -> bit 1, etc.  
    tax
    lda pf2SetBitMask,X
    sta pfBitMask   

.setOrClearPF2
    lda iterations
    ;and #01
    cmp #0
    beq .clearBitPF2
.setBitPF2
    lda pfBitMask
    ora mandelBytes,Y
    sta mandelBytes,Y
    jmp .bailOutUpdateBits
.clearBitPF2
    ; lda pfBitMask
    ; eor #$FF
    ; and mandelBytes,Y
    ; sta mandelBytes,Y
    jmp .bailOutUpdateBits

.bailOutUpdateBits
    POP_REGISTERS
    rts  ; seems like we should return here?
    
initMandelVars:     ;TODO
; Initialize state 
    PUSH_REGISTERS
    lda #$00
; set row and column
    sta row
    sta col


    lda #crStartVal
    sta crStart
    sta cr

; ciStart ds.w  ;
    lda #ciStartVal
    sta ciStart
    sta ci

;c_step ds.w    ; increment between iterations (for both real and imaginary)
; we want to step between -2 and 2 in 32 steps
; 4 / 32 = 1/8 =>    'xxxx00 0000 001000' ==>  0+ 1/8   (2 ^3)
;              =>    'xxxx00 0000 010000' ==> shifted left one bit
;              =>       1111 0000 0001 0000  ==> concatenated to 16 bits
;              =>          f010
;  0001 0010  ==> 0x12  ==> 0x24 after shifting left by one bit
    lda #cStepVal
    sta cStep

; initialize Zr and Zi as 0
    lda #0
    sta zr
    sta zi
    sta zi2
    sta zr2

    lda #MAX_ITERATIONS
    sta iterations
    lda #1
    sta keepIterating
   
   
; clear intermediate values
;fraction_bits ds.b
    lda #00
;zr_p_zi ds.w
    sta zr_p_zi
;zr2_p_zi2 ds.b
    sta zr2_p_zi2
;zr2_m_zi2 ds.w
    sta zr2_m_zi2
    POP_REGISTERS
    rts    

; TODO
nextMandelCol:   ; advance to next colum (i axis). Advance Ci by one step. Wraparound if needed.
    PUSH_REGISTERS
    ldy 1
    inc col
    lda col
    cmp #cols
    beq wrapAround   ; wraparound
    
    ;   sta col
    ; note that our mandelbrot is rotated 90 degrees to take advantage of a mirrored playfield
    ; therefore each column means we increment in the imaginary direction
;     lda ci
;     CLC
;     ;adc cStep   ; update c to next step in imaginary direction
;     adc #1
;     sta ci
    inc ci
    lda #$00
    sta zr
    sta zi
    POP_REGISTERS
    rts
    
; TODO
wrapAround:   ; move cursor back to start of row, advance to next row.  Reset Ci to start, and advance Cr by one step
    lda #0     ; reset to first column
    sta col
    
    lda ciStart   ; reset low and high byte of c (imaginary axis)
    sta ci
    ; fall through to nextMandelRow

nextMandelRow:  ; move cursor to next row
    inc row
    inc cr
:     lda cr      ; add one step to c (lo and then hi)
;     clc
;     ;adc cStep
;     adc #1
;     sta cr

    POP_REGISTERS
    rts  

runActiveTask:
    PUSH_REGISTERS
    lda activeTask

.checkTask_iterate
    cmp #TASK_ITERATE
    bne .checkTask_updatePF
    jsr runNextIter
    lda keepIterating
    cmp #1
    beq .runActiveTask_bailout
    lda #TASK_UPDATEPF
    sta activeTask
    jmp .runActiveTask_bailout

.checkTask_updatePF
    cmp #TASK_UPDATEPF
    bne .checkTask_setup_next_iteration
    jsr updatePfBits
    lda #TASK_SETUP_NEXT_ITERATION
    sta activeTask
    jmp .runActiveTask_bailout

.checkTask_setup_next_iteration
    cmp #TASK_SETUP_NEXT_ITERATION
    bne .checkTask_idle
    lda row
    cmp #rows
    bcc .good_to_iterate
    lda #0
    sta keepIterating
    lda #TASK_IDLE
    sta activeTask
    jmp .runActiveTask_bailout


.good_to_iterate
    
    jsr nextMandelCol
    lda #MAX_ITERATIONS
    sta iterations
    lda #1
    sta keepIterating
    lda #TASK_ITERATE
    sta activeTask
    jmp .runActiveTask_bailout

.checkTask_idle
    cmp #TASK_IDLE
    jmp .runActiveTask_bailout

.runActiveTask_bailout 
    POP_REGISTERS
    rts

runNextIter:        ; run next mandelbrot iteration
    lda row
    cmp #rows
    bcc .runNextIter_iterate   ; skip if we're out of rows to render
.runNextIter_doneIterating
    lda #0
    sta keepIterating
    lda #TASK_IDLE
    sta activeTask
    jmp .runNextIter_bailout

.runNextIter_iterate
    jsr mandel
    lda keepIterating          ; do we have a result?  If not, bail out
    bne .runNextIter_bailout
.runNextIter_render            ; we have a thing to render
    lda #0
    sta keepIterating          ; stop iterating here
    lda #TASK_UPDATEPF
    sta activeTask

.runNextIter_bailout
    rts

;; this has to be at end of code so that it's at the top of memory
    ORG $fffa                ;              set origin to last 6 bytes of 4k rom
interruptVectors:
	.word reset              ;              nmi
	.word reset              ;              reset
	.word reset              ;              irq
;; no code beyond this point.

    MACRO PUSH_REGISTERS
        PHA
        TYA
        PHA
        TXA
        PHA
        PHP
    ENDM

    MACRO POP_REGISTERS
        PLP
        PLA
        TAX
        PLA
        TAY
        PLA
    ENDM
