#include <stdio.h>
#include <stdint.h>
#include <math.h>
#include <stdlib.h>

// Array contents
//  4.6 binary representation
//  xxxxxWWW WWFFFFFF
//       WWW W        --> whole portion
//            FFFFFF  --> fractional portion
//                  0 --> trailing zero (so number points to LSB of its own square)
//  Array Indexing
//  1000 0WWW WFFF FFF0 --> shift left 1 bit, set upper bits to 1000 0xxx
// 
#define MAXINT_10 0x03ff        // clamp squares to max 10 bit value
#define LOWER_10_MASK 0x03ff  // 'AND' mask for lower 10 bits 
                              // extract 10 bit FP number from 16 bit int
#define REAL_MASK  0x03c0      // extract 4 bit real part from FP number
#define FRACT_MASK 0x003f      // extract 6 bit fractional part from FP number                            
#define ORG_ADDR 0x1000       // memory location fixup

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
    // value is 10-bit FP, inset in 16-bit unsigned
    // .....WWW WFFFFFF0
    // .....             => dontcare   (sets base addr for array)
    //      WWW W        => Whole part (0 - 15)
    //           FFFFFF  => Fractional part (-32/32 .. 31/32)
    //                 0 => 

    int16_t whole = 0;
    int16_t fraction = 0;
    int16_t unshifted_1 = 0;

    unshifted_1 = value >> 1;
    whole = (unshifted_1 & 0x0fff) >> 6;
    fraction = (unshifted_1 & 0x003f);
    
    snprintf((char*)outBuffer, maxLen,  "%d.%d", whole, fraction);
    return outBuffer;
}

int main(void) {
    uint16_t squares[1024] = {0};
    uint8_t lowBitStr[9] = {0};
    uint8_t hiBitStr[9] = {0};
    uint8_t printableFp[16] = {0};

    for(int i=-512; i < 512; i++) {
        float f = i * 4.0 / 512.0;   //  -4.0 <= f < 4.0   
        float sq = f * f;  // 0 <= f <= 16

        // sq_fp = 4.6 fixed-point number to be squared
        int16_t sq_fp = floor(sq * 32.0 + 0.5) * 2;

        // clamp so it fits in a 10 bit int
        if(sq_fp > MAXINT_10) sq_fp = MAXINT_10;

        // shift left one bit to put a zero bit in bit0
        sq_fp <<=1;
        sq_fp &= 0xffff;
        
        int16_t whole_fp = (sq_fp >>1 ) >> 6;
        int16_t fract_fp = (sq_fp >> 1) & FRACT_MASK;
        fract_fp <<= 2;

        asBinary(sq_fp & 0x00ff, 8, lowBitStr);
        asBinary(sq_fp >> 8, 8, hiBitStr);

        asPrintableFp(sq_fp, printableFp, 16);

        printf("i=%d, f=%f, sq=%0.8f, sq_fp=%04x, whole_fp=%d, fract_fp=%d (%f)  %s %s ==> %s\n", 
                i,    f,    sq,    sq_fp,      whole_fp,    fract_fp,    fract_fp / 64.0, hiBitStr, lowBitStr, printableFp );

    //    squares[i] = (sq_fp << 1) | ORG_ADDR;
        // printf("squares[%d] = 0x%04x\n", i, squares[i]);

    }
    return 0;
}
