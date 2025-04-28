;;;;; ugly hack to determine include path depending on C or ASM test

.ifdef __IPE_CUSTOM_IVT
    .include "../bin/ipe_macros.asm"
.else
    .include "../../bin/ipe_macros.asm"
.endif

    ;; exported symbols
    .global ipe_ocall
    .global ipe_entry

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; UNPROTECTED STUBS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .sect ".text"
    .global __irq_trampoline

; address of untrusted function passed in r7
ipe_ocall_cont:
    ;eint_all
    call r7
    br #ipe_entry

untrusted_ret:
    ret

ipe_to_untrusted_handler:
    ; fall through to next trampoline

__irq_trampoline:
    mov r8, &__irq_num
    push #ipe_entry
__irq_trampoline_call:
    ; prepare fake stack for ISR reti: r0, r2
    ; r0 return address (#ipe_entry) already pushed before (TODO: what if we get here through ocall?)
    push r2
    ; branch to ISR via untrusted IVT
    mov &__irq_num, r15
    add r15, r15
    clr &__irq_num
    br __vectors_start(r15)

    .sect ".irq_num", "a"
__irq_num:
    .word 0x0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; IPE STUBS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .sect ".ipe_hw_entry", "a"
; single IPE entry point: routes call to function or return address
ipe_entry:
    ; if wanted, disable interrupts from software here:
    ; dint
    ; bic.b #0x10, &__IE1
    ; HW initializes the secure IPE stack to zero
    cmp #0x00, r1
    jne stack_initialized
    mov #ipe_base_stack, r1
stack_initialized:
    ; entry idx=-1 is reserved for the special IRQ dispatch entry point
    cmp #-1, r7
    jeq irq_dispatch

    ; if stack pointer is in the initial position, assume it's an entry call,
    ; not a return from an untrusted function
    cmp #ipe_base_stack, r1
    jne ocall_ret

    ; calling one of the entry points, not returning from an ocall
    ; r7 contains the index of the called function
    ; r12-r15 contain the arguments for the called function
    cmp r7, &max_ecall_index
    jhs index_in_bounds
    mov #0, r7  ; set index to 0 if it was out of bounds
index_in_bounds:
    rla r7
    rla r7      ; r7 = 4*index -- each entry is 4 bytes
    mov ecall_table(r7), r6
    call r6
    add #2, r7  ; get size of return argument
    mov.b ecall_table(r7), r6

ecall_ret:
    clear_argument_regs
    clear_secret_regs
    clr r7
    br #untrusted_ret

; securely call an untrusted function
; r7: address of untrusted function
; r6: bitmap of function arguments
ipe_ocall:
    push_callee_save
    clear_argument_regs
    clear_secret_regs
    br #ipe_ocall_cont

ocall_ret:
    mov &__MPUIPSEGB2, r4
    rla r4
    rla r4
    rla r4
    rla r4
    ; check whether padding number is saved (return from isr)
    mov -34(r4), r5
    cmp #0, r5
    jeq return_from_ocall
return_from_isr:
    mov #7, r6
    sub r5, r6
    add r6, r6
    add #nemesis_mitigation, r6
    br r6
nemesis_ret:
    mov #0, -34(r4)
    pop_all_regs
    reti

return_from_ocall:
    pop_callee_save
    ret


nemesis_mitigation:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    mov #0, -2(r14)
    br #nemesis_ret

; IPE dispatcher for handling interrupts during unprotected code execution
; r8: IRQ number
irq_dispatch:
    cmp #14, r8
    jhs irq_dispatch_ret
    rla r8      ; r8 = 2*index -- each entry is 2 bytes
    mov __ipe_vectors_start(r8), r8

    ; setup a fake reti stack as we call this handler through SW
    push #irq_dispatch_ret
    push r2
    br r8

irq_dispatch_ret:
    clr r6
    br #ecall_ret

; IPE dispatcher for handling interrupts during protected code execution
; divert IPE execution to unprotected handler and back
ipe_irq_trampoline_0:
    inc &__irq_num
ipe_irq_trampoline_1:
    inc &__irq_num
ipe_irq_trampoline_2:
    inc &__irq_num
ipe_irq_trampoline_3:
    inc &__irq_num
ipe_irq_trampoline_4:
    inc &__irq_num
ipe_irq_trampoline_5:
    inc &__irq_num
ipe_irq_trampoline_6:
    inc &__irq_num
ipe_irq_trampoline_7:
    inc &__irq_num
ipe_irq_trampoline_8:
    inc &__irq_num
ipe_irq_trampoline_9:
    inc &__irq_num
ipe_irq_trampoline_10:
    inc &__irq_num
ipe_irq_trampoline_11:
    inc &__irq_num
ipe_irq_trampoline_12:
    inc &__irq_num
ipe_irq_trampoline_13:
    inc &__irq_num
ipe_irq_trampoline_14:
    inc &__irq_num
ipe_irq_trampoline_15:
    inc &__irq_num

    push r6
    push r7
    clr r6
    mov #__irq_trampoline_call, r7
    call #ipe_ocall

; call to ipe_ocall will return here
; continue interrupted IPE execution
ipe_irq_trampoline_reti:
    pop r7
    pop r6
    reti

; IPE-private interrupt vector table; defaults to unprotected pass-through, but
; can be overriden for secure ISRs
.ifndef __IPE_CUSTOM_IVT
    .sect ".ipe_vectors", "a"
ipe_ivt:
    .word ipe_irq_trampoline_0
    .word ipe_irq_trampoline_1
    .word ipe_irq_trampoline_2
    .word ipe_irq_trampoline_3
    .word ipe_irq_trampoline_4
    .word ipe_irq_trampoline_5
    .word ipe_irq_trampoline_6
    .word ipe_irq_trampoline_7
    .word ipe_irq_trampoline_8
    .word ipe_irq_trampoline_9
    .word ipe_irq_trampoline_10
    .word ipe_irq_trampoline_11
    .word ipe_irq_trampoline_12
    .word ipe_irq_trampoline_13
    .word ipe_irq_trampoline_14
    .word ipe_irq_trampoline_15
.endif
