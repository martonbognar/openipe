#include <msp430.h>
#include "../framework/libipe/ipe_support.h"

DECLARE_IPE_STRUCT;

// Wikipedia simple exemple
int rsa_n = 33;
int rsa_e = 3;
int IPE_VAR private_key = 7;


uint16_t IPE_FUNC multiply_mod(uint16_t a, uint16_t b, uint16_t n){
    return (a * b) % n;
}


uint16_t IPE_FUNC modpow(uint16_t a, uint16_t e, uint16_t n){
    uint16_t result = 1;

    while(e > 0){
        // The branch we'll try to gain information on
        if(e & 1){ 
            result = multiply_mod(result, a, n); 
            e--;
        } 
        else{ 
            a = multiply_mod(a, a, n); 
            e /= 2;
        }
    }

    return result;
}

uint16_t IPE_ENTRY rsa_encode(int plain){
    return modpow(plain, rsa_e, rsa_n);
}


uint16_t IPE_ENTRY rsa_decode(int cipher){
    return modpow(cipher, private_key, rsa_n);
}


int main(void)
{
    uint16_t result = 2;
    WDTCTL = WDTPW | WDTHOLD; // Stop Watchdog

    asm __volatile__("mov %0, r8" ::"r"(0xdead) : "r8");

    result = rsa_encode(4);

    asm __volatile__("mov %0, r7" :: "r"(result) : "r7"); 
    asm __volatile__("mov %0, r8" ::"r"(0xbeef) : "r8");
    
    result = rsa_decode(result);

    asm __volatile__("mov %0, r7" :: "r"(result) : "r7"); 
    asm __volatile__("mov %0, r8" ::"r"(0xcaca) : "r8"); 
    
    while (1)
    {
        __no_operation();
    }
    return 0;
}

