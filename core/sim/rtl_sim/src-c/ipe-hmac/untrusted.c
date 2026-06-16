#include <msp430.h>

#include "libipe/ipe_support.h"
#include "libipe/sim_io.h"


int IPE_ENTRY attest(void);

uint8_t mac_region[33] = {0};

int signal_done(int a) {
    return a + 1;
}

int main(void)
{
    WDTCTL = WDTPW | WDTHOLD;                 // Stop Watchdog

    attest();
    ASSERT(mac_region[24] != 0, "mac_region[24] != 0");

    PASS();
}
