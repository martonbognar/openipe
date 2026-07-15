#include <msp430.h>

#include "libipe/ipe_support.h"
#include "libipe/sim_io.h"
#include "libipe/ipe-step.h"

DECLARE_IPE_STRUCT;

uint16_t IPE_VAR seed;


uint16_t IPE_FUNC generate_seed(void) {
    uint16_t seed = 0;
    uint16_t i;

    /* Ensure Timer_A is stopped */
    TACTL = 0;

    /* Run Timer_A from ACLK, continuous mode */
    TACTL = TASSEL_1 | MC_2 | TACLR;

    for (i = 0; i < 16; i++) {
        uint16_t j;
        /* Variable delay using DCO (unpredictable at reset) */
        for (j = 0; j < (TAR & 0x1F) + 50; j++)
            __no_operation();

        seed <<= 1;
        /* Sample unstable low bit of TAR */
        seed |= (TAR & 1);
    }

    TACTL = 0;

    if (seed == 0)
        seed = 0xBEEF;   /* avoid degenerate LCG state */

    return seed;
}

void IPE_ENTRY init_private_key(void){
    seed = generate_seed();
}


int IPE_ENTRY simple_branch(uint16_t entry){
    int result = 0;
    for(int i = 0; i < 16; i++){
        if(((seed >> i) & 1) == (entry & 1)){
            result += 1;
        }
        entry >>= 1;
    }
    return result;
}


int main(void)
{
    uint16_t result;
    WDTCTL = WDTPW | WDTHOLD; // Stop Watchdog
    __enable_interrupt();
    
    init_private_key();
    init_ssteper();

    result = simple_branch(0b0101010101010101);
    ASSERT(result == 5, "simple_branch(0b0101010101010101) == 5");

    PASS();
}
