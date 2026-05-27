#include <msp430.h>
#include "libipe/ipe_support.h"

int ipe_dummy2_outside(int x)
{
    return x + 1;
}

int ipe_dummy2_outside2(int x)
{
    return x + 2;
}

int IPE_VAR b;

int IPE_ENTRY ipe_func(int a);

int IPE_ENTRY ipe_func2(int a)
{
    return ipe_dummy2_outside(a) + ipe_dummy2_outside2(a);
}

int main(void)
{
    int rv;
    WDTCTL = WDTPW | WDTHOLD; // Stop Watchdog
    asm("mov %0, r8" ::"r"(0xdead) : "r8");

    asm("mov %0, r8" ::"m"(b) : "r8");

    rv = ipe_func(0x00CD);
    rv = ipe_func2(0x00CD);
    asm("mov %0, r8" ::"r"(rv) : "r8");

    while (1)
    {
        __no_operation();
    }

    return 0;
}