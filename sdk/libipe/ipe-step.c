#include "ipe-step.h"

#include <msp430.h>

#include "ipe_support.h"
#include "sim_io.h"


#define RESET_TACTL (TA0CTL = TACLR | MC_0)
/*
    TASSEL_2: TimerA is getting its clock from the submain clock
    MC_1: Count to CCR0 then reset
    TACL: clears the module
    TAIE: enables sending interrupts when overflows
*/
#define TACTL_PARAMS_ENABLE (TASSEL_2 | MC_1 | TACLR | TAIE)
#define ENABLE_TACTL (TA0CTL = TACTL_PARAMS_ENABLE)

uint32_t counter;

// Used to initiate timerA 
void init_ssteper(void){
    puts("TimerA initialised");
    counter = 0;

    TA0CCR0 = INIT_LATENCY;
    ENABLE_TACTL;
    
    return;
}

// __attribute__((naked)) is not mandatory now
__attribute__((naked, interrupt(9))) void TimerA_ISR(void){
    counter++;
    uint16_t timing = 0;
    asm __volatile__(
        ".include \"../../core/sim/rtl_sim/bin/template_defs.asm\"\n\t"
 
        // HERE's the code to mesure
        "mov &TAR, r11\n\t"
        "sub %0, r11\n\t"
        "mov r11, %1\n\t"
        ::  
            "i"(BOOTCODE_HANDLING_LATENCY),
            "m"(timing)
        : "r11"
    );

    puts("[*] Instruction timing:");
    // Works bcs cycles are btw 1 and 7
    putchar(48 + timing);
    puts("");

    if(counter < NB_INSTR){
        asm __volatile__(
            // Reset TimerA
            "mov %0, &TACCR0\n\t"
            "mov %1, &TACTL\n\t"
            ::  
            "i"(SSTEP_LATENCY), 
            "i"(TACTL_PARAMS_ENABLE):
        );
    }

    asm __volatile__("reti");
}
