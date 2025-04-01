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
FLICKERMODE = 0
ITERATIONS = 30
rows = 32  ; number of rows to render (two playfield bytes per row)
cols = 16  ; number of coloumns to render (half of a mirrored playfield using PF1 and PF2- 16 bits)
mandelByteCount = 2 * rows
skipRowTimer = 192 * 76 / 64
skipRows = 160


    SEG.U variables
    ORG $80

mandelBytes  ds mandelByteCount
zr  ds.w 1
zi  ds.w 1
cr  ds.w 1
ci  ds.w 1
y   ds.w 1

fraction_bits ds.b

zr_p_zi ds.w 1
zr2_p_zi2 ds.b 1
zr2_p_zi2_lo ds.b 1
zr2_p_zi2_hi ds.b 1
zr2_m_zi2 ds.w 1

; starting points for Cr / Ci
crStart ds.w 1 ;
ciStart ds.w 1 ; 

cStep ds.w   1 ; increment between iterations (both c real and c imaginary)

iterations ds.b 1     ; number of remaining iterations
;iterator_loop

keepIterating ds.b 1  ; have we reached a final result yet?
PF1Shadow ds.b 1     ; shadow copy of PF1 
PF2Shadow ds.b 1     ; shadow copy of PF2 

row ds.b 1            ; current column being rendered (0 .. rows)
col ds.b 1            ; current column (0..15)   (columns 0..7 are in PF1, 8-15 are in PF2)
pfBit ds.b 1          ; bit number of playfield to turn on


    if FLICKERMODE
enableRender ds.b 1
    ENDIF

BLUE           = $9a         ;              define symbol for TIA color (NTSC)
ORANGE         = $2c         
GREEN          = $ca
;==============

    SEG squares
    ORG $f000
    include "squares.asm"
    SEG CODE
    ORG $f800
    include "reversed-bytes.asm"
    include "mandel-kernel.asm"

reset:
	; clear RAM and all TIA registers
	ldx #0                   ;              load the value 0 into (x)
	lda #0                   ;              load the value 0 into (a)

    sta keepIterating;
    sta cr
    sta crStart

clear:                       ;              define a label 
	sta 0,x                  ;              store value in (a) at address of 0 with offset (x)
	inx                      ;              inc (x) by 1. it will count to 255 then rollover to 0
	bne clear                ;              branch up to the 'clear' label if (x) != 0

init:
    lda #03
    sta CTRLPF
    IF FLICKERMODE
    lda #1
    sta enableRender
    ENDIF
    ldy #0
    lda #0
initMandelBytes:
    ora #$f0
    sta mandelBytes,y
    iny
    tya
    cpy #mandelByteCount
    bne initMandelBytes

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
    IF FLICKERMODE
    lda enableRender
    beq skipRender
    lda #0
    sta enableRender
    ENDIF

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

    lda #5
    sta TIM64T
    jsr runNextIter;
    
renderRowLoop:
    lda INTIM
    bne renderRowLoop
renderRowCountUp:
    inx
    inx
    inx
    inx
    inx
    sta WSYNC
    cpy #mandelByteCount
    bne drawMandelBytes
    jmp startFooter
    IF FLICKERMODE
skipRender:
    ldx #0
    lda #skipRowTimer
    sta TIM64T
    lda #1
    sta enableRender
loopSkipRender:
    lda INTIM
    sta WSYNC
    bne loopSkipRender
catchUpRowCount:
    txa
    clc
    adc #skipRows
    tax
    ENDIF
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

initMandelVars:
; Initialize state 

    lda #$00
;mandelBytes  ds mandelByteCount

; starting points for Cr / Ci
    ;  C = -2.0 -2.0i 
    ; 0010 000000   2.0 in fixed point
    ; 1101 111111  1’s complement
    ; 1110 000000   2’s complement
    ; 11 1000 0000   0x3800  (prior)
    ; 11 0000 0000   0x3000  (shift right by 1)

; crStart ds.w  ; 
    lda #00
    sta crStart
    lda #30
    sta crStart + 1

; ciStart ds.w  ; 
    lda #00
    sta ciStart
    lda #30
    sta ciStart + 1

;c_step ds.w    ; increment between iterations (for both real and imaginary)
; we want to step between -2 and 2 in 32 steps
; 4 / 32 = 1/8 =>  0001 0010  ==> 0x12  ==> 0x24 after shifting left by one bit
    lda #$12
    sta cStep



; initialize Zr and ic as 0
   lda #00
   sta zr
   sta zr+1
   sta zi
   sta zi+1
   
;zr  ds.w
;zi  ds.w
;cr  ds.w
;ci  ds.w
;y   ds.w;


;fraction_bits ds.b
    lda #00
    sta fraction_bits


;zr_p_zi ds.w
    sta zr_p_zi
    sta zr_p_zi+1
;zr2_p_zi2 ds.b
    sta zr2_p_zi2
;zr2_p_zi2_lo ds.b
    sta zr2_p_zi2_lo
;zr2_p_zi2_hi ds.b
    sta zr2_p_zi2_hi
;zr2_m_zi2 ds.w
    sta zr2_m_zi2
    sta zr2_m_zi2 + 1



    rts    

;iterations ds.b      ; number of remaining iterations
    lda #1
    sta iterations
    sta keepIterating

;iterator_loop

;keepIterating ds.b   ; have we reached a final result yet?
;PF1_shadow ds.b      ; shadow copy of PF1 
;PF2_shadow ds.b      ; shadow copy of PF2 

;row ds.b             ; current column being rendered (0 .. rows)
;col ds.b             ; current column (0..15)   (columns 0..7 are in PF1, 8-15 are in PF2) 
    rts

updatePfbits:
    lda row
    asl row
    tay              ; y should index to PF1 mandelbyte for current row (PF1)

    lda col          ; which bit are we updating?
    cmp #8
    bcs .updatePF2    ; equal or greater than 8 -> we are in PF2
.updatePF1:          ; PF1:  col 01234567 --> bit 76543210
; col 0 -> bit 7, col 1 -> bit 6, etc
    lda #7
    SEC
    sbc col
    sta pfBit
    lda #1
    asl pfBit
    ora PF1Shadow
    sta PF1Shadow
    sta mandelBytes,Y

.updatePF2:          ;  PF2:   col 89abcdef --> bit 01234567
    SEC
    sbc #8            ; PF2 bits are in opposite direction of PF1
                      ; col 8 -> bit 0, col 9 -> bit 1, etc.  
    sta pfBit
    lda #1
    asl pfBit
    ora PF2Shadow
    sta PF2Shadow     ; fixme - we have to actually update the right field in mandelbytes
    INY               ; one more byte to point at PF2
    sta mandelBytes,y 

;.blankBitPF1

;.blankBitPF2

    rts  ; seems like we should return here?
    

nextMandelCol:
    lda col
    clc 
    adc #1
    cmp #cols
    beq wrapAround   ; wraparound
    
    sta col
    ; note that our mandelbrot is rotated 90 degrees to take advantage of a mirrored playfield
    ; therefore each column means we increment in the imaginary direction
    lda ci
    CLC
    adc #cStep   ; update c to next step in imaginary direction
    sta ci
    
    lda #ci+1
    clc
    adc #cStep + 1
    sta ci + 1
    
    rts
    
wrapAround:   ; move cursor back to start of row
    lda #0     ; reset to first column
    sta col
    
    lda ciStart   ; reset low and high byte of c (imaginary axis)
    sta ci
    lda ciStart+1
    sta ci+1
    ; fall through to nextMandelRow

nextMandelRow:  ; move cursor to next row
    lda row
    clc 
    adc #1      ; increment cursor row
    sta row


    lda cr      ; add one step to c (lo and then hi)
    clc
    adc cStep
    sta cr

    lda cr+1
    CLC
    adc cStep + 1
    sta cr+1

    rts  



runNextIter:        ; run next mandelbrot iteration
    jsr mandel
    rts


;; this has to be at end of code so that it's at the top of memory
    ORG $fffa                ;              set origin to last 6 bytes of 4k rom
interruptVectors:
	.word reset              ;              nmi
	.word reset              ;              reset
	.word reset              ;              irq
;; no code beyond this point.
