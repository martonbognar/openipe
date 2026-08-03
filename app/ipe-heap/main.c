#include <msp430.h>
#include <stdlib.h>

#include "libipe/ipe_support.h"
#include "libipe/sim_io.h"
#include "libipe/ipe-memory.h"

DECLARE_IPE_STRUCT;

int* IPE_VAR ipe_array;
size_t IPE_VAR l_ipe_array;


void IPE_ENTRY compute_array(int n){
    ipe_array = (int*)ipe_malloc(n * sizeof(int));
    ASSERT(ipe_array != NULL, "[*] Check ptr");

    l_ipe_array = n;

    for(int i = 0; i < n; i++){
        ipe_array[i] = i;
    }
} 


int IPE_ENTRY get_sum(){
    int sum = 0;
    for(int i = 0; i < l_ipe_array; i++){
        sum += ipe_array[i];
    }

    ipe_free(ipe_array);
    return sum;
}

void IPE_ENTRY init(){
    initialise_heap();
}


int main(void)
{
    WDTCTL = WDTPW | WDTHOLD; // Stop Watchdog
    init();

    /* M_c(n) = n(n + 5)
    It should then be failing after creating 62 arrays (when M_c(n) > 0x1000)
    */
    for(int i = 1; i < 63; i++){
        compute_array(i);
        ASSERT(get_sum() == i * (i - 1) / 2, "[*] Compute sum");
    }
    
    PASS();
}
