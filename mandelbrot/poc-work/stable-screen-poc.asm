; Stable screen for rendering Mandelbrot
; Proof of concept - displays contents of bytes containing mandelbrot pixes
;                  - does not use timers or any fancy time slicing
;
; Based on 8blit - S01E02 Generating a stable screen
; 
;
; Become a Patron - https://patreon.com/8blit
; 8blit Merch - https://8blit.myspreadshop.com/
; Subscribe to 8Blit - https://www.youtube.com/8blit?sub_confirmation=1
; Follow on Facebook - https://www.facebook.com/8Blit
; Follow on Instagram - https://www.instagram.com/8blit
; Visit the Website - https://www.8blit.com 

	processor 6502
	include "vcs.h"

rows = 48  ; number of rows to render (two playfield bytes per row)
mandelByteCount = 2 * rows


    SEG.U variables
    ORG $80
mandelBytes  ds mandelByteCount



BLUE           = $9a         ;              define symbol for TIA color (NTSC)
ORANGE         = $2c         
GREEN          = $ca

	seg
	org $f000

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

    inx
    sta WSYNC
    inx
    sta WSYNC
    inx
    sta WSYNC
;    inx
;     sta WSYNC
;     inx
;     sta WSYNC
    cpy #mandelByteCount
    bne drawMandelBytes

startFooter:
    lda #ORANGE
    sta COLUBK
    lda #$00
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

	org $fffa                ;              set origin to last 6 bytes of 4k rom
	
interruptVectors:
	.word reset              ;              nmi
	.word reset              ;              reset
	.word reset              ;              irq

