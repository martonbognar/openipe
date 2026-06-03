/*---------------------------------------------------------------------------*/
/*                          IPE-SPECIFIC MACROS                              */
/*---------------------------------------------------------------------------*/

.ifndef __IPE_MACROS_INCLUDE
.set __IPE_MACROS_INCLUDE, 1

; enables maskable interrupts
.macro eint_all
    nop
    eint
    ; bit.b #0x10, &__IE1
    nop
 .endm

; disables maskable interrupts
.macro dint_all
    dint
    ; bic.b #0x10, &__IE1
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

; pop callee-save registers (except for r6 and r7, carrying metadata about the called untrusted function)
; https://mspgcc.sourceforge.net/manual/c1225.html
.macro pop_callee_save
    pop r11
    pop r10
    pop r9
    pop r8
    pop r5
    pop r4
    .endm

; push callee-save registers
.macro push_callee_save
    push r4
    push r5
    push r8
    push r9
    push r10
    push r11
    .endm

; clear callee-save registers
; (excluding r7, carrying metadata about called untrusted function)
; (including r2, the status register)
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

; get starting address of IPE region 1 (originally shifted by 4 in the boundary register)
.macro get_ipe_start REG
    mov &MPUIPSEGB1, \REG
    rla \REG
    rla \REG
    rla \REG
    rla \REG
    .endm

; Get the start address of the currently active IPE region (if none are active, the start address of region 1 will be returned.)
.macro get_ipe_start_mult REG
    push r10
    mov #IPE_ACTIVE, \REG
    sub #2, \REG
    mov &IPE_ACTIVE, r10
get_ipe_start_loop\@:
    add #8, \REG
    rra r10
    jc end_get_ipe_start\@
    jmp get_ipe_start_loop\@
end_get_ipe_start\@:
    mov 0(\REG), \REG
    rla \REG
    rla \REG
    rla \REG
    rla \REG
    pop r10
    .endm

; get entry address of IPE region 1
.macro get_ipe_entry REG
    get_ipe_start \REG
    add #8, \REG
    .endm

; get entry address of currently active IPE region
.macro get_ipe_entry_mult REG
    get_ipe_start_mult \REG
    add #8, \REG
    .endm

; get entry address of specific IPE region according to one-hot encoded array
; will return entry of region in LSB in array 
; REG2 contains one-hot encoded array
; REG will contain entry point
.macro get_specific_ipe_entry REG REG2
    push r10
    mov #IPE_ACTIVE, \REG
    sub #2, \REG
    mov \REG2, r10
get_spec_ipe_loop\@:
    add #8, \REG
    rra r10
    jc end_get_spec_ipe\@
    jmp get_spec_ipe_loop\@
end_get_spec_ipe\@:
    mov 0(\REG), \REG
    rla \REG
    rla \REG
    rla \REG
    rla \REG
    pop r10
    add #8, \REG
    .endm


; get end address of IPE region 1 (originally shifted by 4 in the boundary register)
.macro get_ipe_end REG
    mov &MPUIPSEGB2, \REG
    rla \REG
    rla \REG
    rla \REG
    rla \REG
    .endm


; Get the end address of the currently active IPE region (if none are active, the end address of region 1 will be returned.)
.macro get_ipe_end_mult REG
    push r10
    mov #IPE_ACTIVE, \REG
    sub #4, \REG
    mov &IPE_ACTIVE, r10
get_ipe_end_loop\@:
    add #8, \REG
    rra r10
    jc end_get_ipe_end\@
    jmp get_ipe_end_loop\@
end_get_ipe_end\@:
    mov 0(\REG), \REG
    rla \REG
    rla \REG
    rla \REG
    rla \REG
    pop r10
    .endm


; checks whether the IPE of number REG is enabled and stores 1 in REG2 if it is the case
.macro check_ipe_enabled REG REG2
    push r10
    push r11
    mov \REG, r11
    mov #__MPUIPC0, r10
enable_check_loop\@:
    cmp #1, r11
    jeq enable_check_loop_end\@
    dec r11
    add #8, r10
    jmp enable_check_loop\@
enable_check_loop_end\@:
    bit #0x40, 0(r10)
    adc \REG2
    pop r11
    pop r10
    .endm


; checks whether for the current IPE executing the handler for interrupt REG is registered for this enclave
; REG2 contains the result
.macro check_handler_registered REG REG2
    push r10
    push r11
    mov #__bootcode_ivt_start, r10
    sub.w #10, r10
    mov &IPE_ACTIVE, r11
ipe_select_loop\@:
    add.w #0x2, r10
    rra r11
    jnc ipe_select_loop\@
    mov 0(r10), r10
isr_select_loop\@:
    tst \REG
    jz check_isr\@
    rra r10
    dec \REG
    jmp isr_select_loop\@
check_isr\@:
    rra r10
    adc \REG2    
    pop r10
    pop r11
    .endm
    
.endif

