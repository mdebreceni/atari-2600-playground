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


#define MAXUINT_8 0xff       // clamp squares to max unsigned 8-bit value
#define FP_MODE  44   // either 44 or 35

#if FP_MODE == 44
    #define WHOLE_BITS 4
    #define FRACT_BITS 4
    #define WHOLE_MASK  0xf0    // extract 3 bit whole part from FP number
    #define FRACT_MASK  0x0f    // extract 5 bit fractional part from FP number                            
#else
    #define WHOLE_BITS 3
    #define FRACT_BITS 5
    #define WHOLE_MASK  0xe0
    #define FRACT_MASK  0x1f
#endif


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

uint8_t* asPrintableFp(int16_t value, uint8_t* outBuffer, int maxLen) {
    // FIXME:  Does not like negative numbers.  
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
    printf("; %d.%d fixed point mode\n", WHOLE_BITS, FRACT_BITS);
    printf("wholeMask = #$%02x\n", WHOLE_MASK);
    printf("fractMask = #$%02x\n", FRACT_MASK);

    int8_t cStartVal = 0 - (2 << FRACT_BITS);   // hopefully this gives us -2, properly shifted      
    int8_t cStep = 1 << (FRACT_BITS - 3);     // 0.125 = 2 ^ -3, and 2^0 = 1.  
                                              // The bit for '1' is FRACT_BITS from the right.

    printf("cStartVal = #$%02x\n", (uint8_t)cStartVal);
    printf("cStepVal  = #$%02x\n", cStep);
    printf("\n");
    int offset = 0;
    int words_per_row = 16;

    printf("%s:", label);
    if(orgAddr != 0xffff) {
        printf("    ORG $%04x\n", orgAddr);
    }

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
    uint8_t fp_bitStr[9] = {0};
    uint8_t sqfp_bitStr[9] = {0};
    uint8_t printableFp[16] = {0};
    uint8_t printableSqFp[16] = {0};

    for(int i=-128; i < 128; i++) {
        int8_t fp = i;
        int8_t fp_whole = (fp) >> FRACT_BITS;
        int8_t fp_fract = (fp) & FRACT_MASK;

        uint16_t sq_fp = i * i;   // multiply raw numbers
        sq_fp >>= FRACT_BITS;     // magnitude correction
        if (sq_fp > MAXUINT_8) {
            // clamp to MAXINT_8
            sq_fp = MAXUINT_8;
        }
        int16_t sq_fp_whole = (sq_fp) >> FRACT_BITS;
        int16_t sq_fp_fract = (sq_fp) & FRACT_MASK;

        asBinary(fp & 0x00ff, 8, fp_bitStr);
        asBinary(sq_fp & 0x00ff, 8, sqfp_bitStr);
        asPrintableFp(sq_fp, printableSqFp, 16);
        asPrintableFp(fp, printableFp, 16);

        uint16_t idx = (uint16_t) i;
        idx &= 0xff;
        printf("; i=%d, idx=%d fp=%04x fp_whole=%04x, fp_fract=%04x, printableFp=%s, fp_bits=%s || sq_fp=%04x, sq_fp_whole=%d, sq_fp_fract=%d (%0.8f)  %s ==> %s\n", 
                  i,    idx,   fp,     fp_whole,      fp_fract,      printableFp,      fp_bitStr,    sq_fp,      sq_fp_whole,    sq_fp_fract,    1.0 * sq_fp_fract / (1 << FRACT_BITS), sqfp_bitStr, printableFp );
        squares[idx] = sq_fp;

    }
    printf("\n");

    makeDasmData(squares, 256, "squares", 0xffff);
    return 0;
}
