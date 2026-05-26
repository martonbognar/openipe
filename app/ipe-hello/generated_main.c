#include <msp430.h>
#include "libipe/ipe_support.h"

DECLARE_IPE_STRUCT;

int IPE_VAR b = 0xAB00;

void IPE_FUNC ipe_dummy1(void)
{
    return;
}

int ipe_dummy2_outside(int x)
{
    return x + 1;
}

int main(void)
{
    int rv;
    WDTCTL = WDTPW | WDTHOLD; // Stop Watchdog
    asm("mov %0, r8" ::"r"(0xdead) : "r8");

    asm("mov %0, r8" ::"m"(b) : "r8");

    rv = ipe_func(0x00CD);
    asm("mov %0, r8" ::"r"(rv) : "r8");

    while (1)
    {
        __no_operation();
    }

    return 0;
}

