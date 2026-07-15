#include <msp430.h>

#include "libipe/ipe_support.h"
#include "libipe/sim_io.h"

#include "bsl.h"

DECLARE_IPE_STRUCT;

int main(void)
{
    WDTCTL = WDTPW | WDTHOLD; // Stop Watchdog
    __enable_interrupt();
    
    char dummy_ivt[BSL_PASSWORD_LENGTH];
    char good_ivt[BSL_PASSWORD_LENGTH];

    for(int i = 0; i < BSL_PASSWORD_LENGTH; i++){
        dummy_ivt[i] = i;
        if(i % 2 == 0)
            good_ivt[i] = 0xca;
        else
            good_ivt[i] = 0x80;
    }

    ASSERT(BSL430_unlock_BSL_balanced(dummy_ivt) == BSL_PASSWORD_ERROR, "[*] Wrong password computation balanced");
    ASSERT(BSL430_unlock_BSL_balanced(good_ivt) == SUCCESSFUL_OPERATION, "[*] Good password computation balanced");

    ASSERT(BSL430_unlock_BSL_unbalanced(dummy_ivt) == BSL_PASSWORD_ERROR, "[*] Wrong password computation unbalanced");
    ASSERT(BSL430_unlock_BSL_unbalanced(good_ivt) == SUCCESSFUL_OPERATION, "[*] Good password computation unbalanced");

    PASS();
}
