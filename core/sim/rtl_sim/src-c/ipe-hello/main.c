#include <msp430.h>
#include "libipe/ipe_support.h"
#include "libipe/sim_io.h"

int ipe_dummy2_outside(int x)
{
    return x + 1;
}

int ipe_dummy2_outside2(uint64_t x)
{
    return x + 2;
}

int IPE_VAR c;

uint16_t IPE_ENTRY ipe_func(int a);

void IPE_ENTRY another_entry(void)
{
    return;
}

int IPE_ENTRY ipe_func2(int a)
{
    return ipe_dummy2_outside(a) * ipe_dummy2_outside2(a);
}

int main(void)
{
    int rv;
    WDTCTL = WDTPW | WDTHOLD; // Stop Watchdog

    rv = ipe_func(0xCD);
    ASSERT((uint16_t)rv == 0xABCDu, "ipe_func(0xCD) == 0xABCD");

    rv = ipe_func2(0);
    ASSERT(rv == 2, "ipe_func2(0) == 2");

    PASS();
}