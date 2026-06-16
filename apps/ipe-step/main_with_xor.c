#include <msp430.h>
#include "libipe/ipe_support.h"
#include "ssteper.h"

DECLARE_IPE_STRUCT;

// In theory we're not supposed to use the same key twice but yeah 
// In fact we're using a xor cipher rather than an otp but nvm it's otp on Z/2Z
uint16_t IPE_VAR private_key = 0b0111010101010101;


uint64_t IPE_FUNC custom_16_xor(uint16_t n, uint16_t m){
    uint16_t result = 0;

    for(int i = 0; i < 16; i++){
        if((n & 1) != (m & 1)){
            result += (1 << i);
        }

        n >>= 1;
        m >>= 1;
    }
    return result;
}

uint16_t IPE_ENTRY otp_encode(uint16_t plain){
    return custom_16_xor(private_key, plain);
}


uint16_t IPE_ENTRY otp_decode(uint16_t cipher){
    return private_key ^ cipher;
}


int main(void)
{
    uint16_t result;
    WDTCTL = WDTPW | WDTHOLD; // Stop Watchdog
    __enable_interrupt();

    asm __volatile__("mov %0, r8" ::"r"(0xdead) : "r8");
    
    init_ssteper();

    result = otp_encode(1);

    asm __volatile__("mov %0, r7" :: "r"(result) : "r7"); 
    asm __volatile__("mov %0, r8" ::"r"(0xbeef) : "r8");   
    
    while (1)
    {
        __no_operation();
    }
    return 0;
}
