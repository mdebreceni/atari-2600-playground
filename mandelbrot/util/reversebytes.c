#include <stdio.h>
#include <stdint.h>

uint8_t* asbinary(uint8_t ch) {
    static uint8_t bits[8];
    uint8_t mask = 0x80;

    for (int bit=0; bit<8; bit++) {
        if(ch & mask) {
            bits[bit] = '1';
        } else {
            bits[bit] = '0';
        }
        mask >>=1;
    }
    return bits;

}
void debug_printReversedBits(uint8_t *reversed_byte_array_256) {
    for (uint16_t ch = 0; ch < 256; ch++) {
        uint8_t ch_rvs = reversed_byte_array_256[ch];
        printf("%d %02x %02x %s ", ch, ch, ch_rvs, asbinary(ch));
        printf("%s\n", asbinary(ch_rvs));
    }
}

void makeDasmHex(uint8_t *byteData, uint16_t count, char* label, uint16_t orgAddr) {
    printf("; programmatically generated bit-reversed bytes (0 through 255)\n");
    printf("%s:", label);
    if(orgAddr != 0xffff) {
        printf("    ORG $%04x\n", orgAddr);
    }
    int offset = 0;
    int bytes_per_row = 16;
    while(offset < count) {
        if(offset % bytes_per_row == 0) {
            printf("\n    HEX ");
        } 
        printf("%02x ", byteData[offset]);
        offset++;
    }
    printf("\n");
}


int main(int argc, char *argv[]) {
    uint16_t ch;
    uint8_t reversed[256] = {0};

    for (ch = 0; ch < 256; ch++) {
        uint8_t mask = 0x01;
        uint8_t revmask = 0x80;
        uint8_t accum = 0x00;
        for(int bit=0; bit<8; bit++) {
            if(ch & mask) {
                accum ^= revmask;
            }
            mask <<=1;
            revmask >>=1;
        }
        reversed[ch] = accum;
    }

    if(0) debug_printReversedBits(reversed);
    makeDasmHex(reversed, 256, "reversed", 0xffff);

    return 0;
}

