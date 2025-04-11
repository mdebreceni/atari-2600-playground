; Stable screen 
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

rows = 16  ; number of rows to render (two playfield bytes per row)
rickByteCount = 2 * rows


    SEG.U variables
    ORG $80


BLUE           = $9a         ;              define symbol for TIA color (NTSC)
ORANGE         = $2c         
GREEN          = $ca
PALE_BG        = $2e
BLACK          = $00
	seg
	org $f000

rickBytes:
    dc.b %00000000,%00000000
    dc.b %00000001,%00000011
    dc.b %00000001,%00001111
    dc.b %00000001,%00000000

    dc.b %00000000,%00000000
    dc.b %00000000,%00000000
    dc.b %00000000,%00000000
    dc.b %00000011,%00000110

    dc.b %00000110,%00011111
    dc.b %00000111,%00011110
    dc.b %00000110,%00010111
    dc.b %00000110,%00010110

    dc.b %00000110,%00111111
    dc.b %00000110,%00111100
    dc.b %00000110,%00001111
    dc.b %00000110,%00011111



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
; initRickBytes:
;     sta rickBytes,y
;     iny
;     tya
;     cpy #rickByteCount
;     bne initRickBytes

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
    lda #0
; drawAboveRick:
;     sta WSYNC
;     sta PF0
;     sta PF1
;     INX
;     cpx #20
;     bne drawAboveRick
    
startRickBytes:
    ldx #0
    ldy #0
drawRickBytes:
    lda #0
	sta WSYNC
    sta PF0
    lda rickBytes,y
    sta PF1
    iny
    lda rickBytes,y
    sta PF2
    iny

    inx
    sta WSYNC
    inx
    sta WSYNC
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
    cpy #rickByteCount
    bne drawRickBytes

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

