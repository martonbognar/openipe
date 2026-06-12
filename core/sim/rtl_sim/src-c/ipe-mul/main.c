#include <msp430.h>
#include "libipe/ipe_support.h"

DECLARE_IPE_STRUCT;

uint16_t IPE_ENTRY mul(uint16_t a, uint16_t b){
    return a * b;
}

uint16_t unprotected_mul(uint16_t a, uint16_t b){
    return a * b;
}

int main(void)
{
    uint16_t result = 2;
    WDTCTL = WDTPW | WDTHOLD; // Stop Watchdog

    result = unprotected_mul(7, 8);
    asm __volatile__("mov %0, r7" :: "r"(result) : "r7"); 
    asm __volatile__("mov %0, r8" ::"r"(0xdead) : "r8");

    result = mul(4, 5);

    asm __volatile__("mov %0, r7" :: "r"(result) : "r7"); 
    asm __volatile__("mov %0, r8" ::"r"(0xbeef) : "r8");
    
    EXIT();
}

