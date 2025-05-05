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

; address of untrusted function passed in r7
ipe_ocall_cont:
    call r7
    br #ipe_entry

untrusted_ret:
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; IPE STUBS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .sect ".ipe_hw_entry", "a"
; single IPE entry point: routes call to function or return address
ipe_entry:
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

nemesis_mitigation:
    nop
    nop
    nop
    nop
    nop
    nop
    nop

nemesis_ret:
    mov #0, -34(r4)
    pop_all_regs
    reti

return_from_ocall:
    pop_callee_save
    ret


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

undef_irq:
    reti

; IPE-private interrupt vector table; defaults to no-op, but
; can be overriden for secure ISRs
.ifndef __IPE_CUSTOM_IVT
    .sect ".ipe_vectors", "a"
ipe_ivt:
    .word undef_irq
    .word undef_irq
    .word undef_irq
    .word undef_irq
    .word undef_irq
    .word undef_irq
    .word undef_irq
    .word undef_irq
    .word undef_irq
    .word undef_irq
    .word undef_irq
    .word undef_irq
    .word undef_irq
    .word undef_irq
    .word undef_irq
    .word undef_irq
.endif
