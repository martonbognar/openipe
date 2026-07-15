#include <msp430.h>
#include "libipe/ipe_support.h"
#include "libipe/sim_io.h"

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
    ASSERT(result == 56, "unprotected_mul(7,8) == 56");

    result = mul(4, 5);
    ASSERT(result == 20, "mul(4,5) == 20");

    PASS();
}
