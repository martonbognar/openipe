#include "libipe/ipe_support.h"

int ipe_dummy2_outside(uint16_t x);

DECLARE_IPE_STRUCT;

int IPE_VAR b = 0xAB00;

void IPE_FUNC ipe_dummy1(void)
{
    return;
}

int IPE_ENTRY ipe_func(int a)
{
    char *c = (char *)ipe_dummy1;
    *c = 0;
    return (a + b) * ipe_dummy2_outside(0);
}

void IPE_ENTRY another_entry(void)
{
    return;
}
