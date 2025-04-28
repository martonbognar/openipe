/*---------------------------------------------------------------------------*/
/*                          IPE-SPECIFIC MACROS                              */
/*---------------------------------------------------------------------------*/

.ifndef __IPE_MACROS_INCLUDE
.set __IPE_MACROS_INCLUDE, 1

; enables both maskable and non-maskable interrupts
.macro eint_all
    nop
    eint
    nop
 .endm

; disables both maskable and non-maskable interrupts
.macro dint_all
    dint
    nop
.endm

.macro pop_all_regs
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop r7
    pop r6
    pop r5
    pop r4
    .endm

.macro clear_all_regs
    clr r15
    clr r14
    clr r13
    clr r12
    clr r11
    clr r10
    clr r9
    clr r8
    clr r7
    clr r6
    clr r5
    clr r4
    .endm

; pop callee-save registers (except for r6 and r7, carrying metadata about called untrusted function)
.macro pop_callee_save
    pop r11
    pop r10
    pop r9
    pop r8
    pop r5
    pop r4
    .endm

; push callee-save registers
; https://mspgcc.sourceforge.net/manual/c1225.html
.macro push_callee_save
    push r4
    push r5
    push r8
    push r9
    push r10
    push r11
    .endm

.macro push_all_regs
    push r4
    push r5
    push r6
    push r7
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
    .endm

; clear callee-save registers (except for r7, carrying metadata about called untrusted function)
.macro clear_secret_regs
    clr r2
    clr r4
    clr r5
    clr r6
    clr r8
    clr r9
    clr r10
    clr r11
    .endm

; clear argument registers except for those carrying a return value
; r6 contains the bitmap of the return value / argument pattern
.macro clear_argument_regs
    rra r6
    jc 1f
    clr r12
    rra r6
    jc 1f
    clr r13
    rra r6
    jc 1f
    clr r14
    rra r6
    jc 1f
    clr r15
1:
    .endm

.macro get_ipe_start REG
    mov &MPUIPSEGB1, \REG
    rla \REG
    rla \REG
    rla \REG
    rla \REG
    .endm

.macro get_ipe_entry REG
    get_ipe_start \REG
    add #16, \REG
    .endm

.macro get_ipe_end REG
    mov &MPUIPSEGB2, \REG
    rla \REG
    rla \REG
    rla \REG
    rla \REG
    .endm

.endif
