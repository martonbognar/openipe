#include "libipe/ipe_support.h"

int ipe_dummy2_outside(uint16_t x);

DECLARE_IPE_STRUCT;

int IPE_VAR b = 0xAB00;

void IPE_FUNC ipe_dummy1(void)
{
    return;
}

int IPE_FUNC ipe_div(int a, int b)
{
    return a / b;
}

void IPE_ENTRY another_entry(void);

int IPE_ENTRY ipe_func(int a)
{
    char *c = (char *)ipe_dummy1;
    *c = 0;
    another_entry();
    return (a + b) * ipe_dummy2_outside(0);
}
