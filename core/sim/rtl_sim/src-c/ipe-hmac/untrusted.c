#include <stdint.h>
#include <msp430.h>
#include "output/generated_ipe_header.h"

uint8_t mac_region[33] = {0};

int signal_done(int a) {
    return a + 1;
}

int main(void)
{
    WDTCTL = WDTPW | WDTHOLD;                 // Stop Watchdog

    asm("mov %0, r8"::"r"(0xdead) :"r8");
    attest();
    asm("mov %0, r8"::"m"(mac_region[24]) :"r8");

    return 0;
}
