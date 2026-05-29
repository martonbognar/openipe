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

int IPE_VAR c;

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

    asm("mov %0, r8" ::"m"(c) : "r8");

    rv = ipe_func(0xCD);
    asm("mov %0, r8" ::"r"(rv) : "r8");
    asm("mov %0, r9" ::"r"(0xcaca) : "r9");

    rv = ipe_func2(0);
    asm("mov %0, r8" ::"r"(rv) : "r8");
    asm("mov %0, r9" ::"r"(0xcacb) : "r9");

    while (1)
    {
        __no_operation();
    }

    return 0;
}