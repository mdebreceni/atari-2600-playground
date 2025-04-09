#include <stdio.h>
#include <stdint.h>
#include <math.h>
#include <stdlib.h>

// Array contents
//  3.5 binary representation
//       WWW         --> whole portion
//          FFFFFFF  --> fractional portio
//  Array Indexing
//  base address + y (since array is 256 bytes, an 8-bit index can access entire array)
// 
#define MAXUINT_8 0xff       // clamp squares to max unsigned 8-bit value
#define WHOLE_MASK  0xe0    // extract 3 bit whole part from FP number
#define WHOLE_BITS  3
#define FRACT_MASK  0x1f    // extract 5 bit fractional part from FP number                            
#define FRACT_BITS  5
#define ORG_ADDR 0xf000     // memory location fixup

uint8_t* asBinary(uint8_t ch, int bitWidth, uint8_t* outBits ) {
    uint8_t mask = 0x80;
    int n=0;

    for (n=0; n<bitWidth; n++) {
        if(ch & mask) {
            outBits[n] = '1';
        } else {
            outBits[n] = '0';
        }
        mask >>=1;
    }
    outBits[n] = 0;
    return outBits;
}

uint8_t* asPrintableFp(uint16_t value, uint8_t* outBuffer, int maxLen) {
    // value is 8-bit FP
    // WWWFFFFF    
    // WWW       => Whole part (0 - 15)
    //    FFFFF  => Fractional part (-32/32 .. 31/32)
    
    int16_t whole = 0;
    int16_t fraction = 0;
    
    whole = (value & WHOLE_MASK) >> FRACT_BITS;
    fraction = (value & FRACT_MASK);
    
    snprintf((char*)outBuffer, maxLen,  "; %f", 0.0 + whole + 1.0 * fraction / (1 << FRACT_BITS));
    return outBuffer;
}

void makeDasmData(uint16_t *squaresTable, uint16_t count, char* label, uint16_t orgAddr) {
    printf("; programmatically generated table of squares\n");
    printf("; %d.%d bit fixed-point\n", WHOLE_BITS, FRACT_BITS);
    printf("%s:", label);
    if(orgAddr != 0xffff) {
        printf("    ORG $%04x\n", orgAddr);
    }
    int offset = 0;
    int words_per_row = 16;
    while(offset < count) {
        if(offset % words_per_row == 0) {
            printf("\n    DC.b ");
        } else {
            printf(",");
        }
        printf("$%02x", squaresTable[offset]);
        offset++;
    }
    printf("\n");
}

int main(void) {
    uint16_t squares[256] = {0};
    uint8_t lowBitStr[9] = {0};
    uint8_t printableFp[16] = {0};

    for(int i=-128; i < 128; i++) {
        uint16_t sq_fp = i * i;   // multiply raw numbers
        sq_fp >>= FRACT_BITS;     // magnitude correction
        if (sq_fp > MAXUINT_8) {
            // clamp to MAXINT_8
            sq_fp = MAXUINT_8;
        }
        
        int16_t whole_fp = (sq_fp) >> FRACT_BITS;
        int16_t fract_fp = (sq_fp) & FRACT_MASK;
  
        asBinary(sq_fp & 0x00ff, 8, lowBitStr);
        asPrintableFp(sq_fp, printableFp, 16);

        uint16_t idx = (uint16_t) i;
        idx &= 0xff;
        printf("; i=%d, idx=%d sq_fp=%04x, whole_fp=%d, fract_fp=%d (%0.8f)  %s ==> %s\n", 
                i,    idx,   sq_fp,      whole_fp,    fract_fp,    1.0 * fract_fp / (1 << FRACT_BITS), lowBitStr, printableFp );
        squares[idx] = sq_fp;

    }
//    for(int i=48; i<49; i++) {
//        printf("%02x ", squares[i]);
//    }
    printf("\n");
    makeDasmData(squares, 256, "squares", 0xffff);
    return 0;
}
