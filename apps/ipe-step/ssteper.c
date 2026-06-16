#include "ssteper.h"

#include <msp430.h>
#include "libipe/ipe_support.h"


#define RESET_TACTL (TA0CTL = TACLR | MC_0)
/*
    TASSEL_2: TimerA is getting its clock from the submain clock
    MC_1: Count to CCR0 then reset
    TACL: clears the module
    TAIE: enables sending interrupts when overflows
*/
#define TACTL_PARAMS_ENABLE (TASSEL_2 | MC_1 | TACLR | TAIE)
#define ENABLE_TACTL (TA0CTL = TACTL_PARAMS_ENABLE)

uint16_t counter;

// Used to initiate timerA 
void init_ssteper(void){
    asm __volatile__("mov %0, r8" ::"r"(0xcaca) : "r8");
    counter = 0;

    TA0CCR0 = INIT_LATENCY;
    ENABLE_TACTL;
    
    return;
}

// __attribute__((naked)) is not mandatory now
__attribute__((naked, interrupt(9))) void TimerA_ISR(void){
    counter++;
    asm __volatile__(
        ".include \"../../core/sim/rtl_sim/bin/template_defs.asm\"\n\t"
 
        // HERE's the code to mesure
        "mov &TAR, r11\n\t"
        "sub %0, r11\n\t"

        // Transmit to monitor but should find another way
        "mov #0xcacb, r12\n\t"
        "mov #0, r12\n\t"

        // No need to activate timerA again
        "cmp %1, %2\n\t"
        "jeq %=f\n\t"

        // Reset TimerA
        "mov %3, &TACCR0\n\t"
        "mov %4, &TACTL\n\t"
        "%=:\n\t"
        "reti"
        ::  
            "i"(BOOTCODE_HANDLING_LATENCY),
            "i"(NB_INSTR),
            "m"(counter),
            "i"(SSTEP_LATENCY), 
            "i"(TACTL_PARAMS_ENABLE):
    );
}
