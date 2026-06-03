;;;;; ugly hack to determine include path depending on C or ASM test

.ifdef __IPE_CUSTOM_IVT
    .include "../bin/ipe_macros.asm"
.else
    .include "../../bin/ipe_macros.asm"
.endif

    ;; exported symbols
    .global ipe_ocall
    .global ipe_entry

    .global ipe_ocall2
    .global ipe_entry2

    .global ipe_ocall3
    .global ipe_entry3

    .global ipe_ocall4
    .global ipe_entry4

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; UNPROTECTED STUBS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .sect ".text"

; address of untrusted function passed in r7
ipe_ocall_cont:
    call r7
    br #ipe_entry

ipe_ocall_cont2:
    call r7
    br #ipe_entry2

ipe_ocall_cont3:
    call r7
    br #ipe_entry3

ipe_ocall_cont4:
    call r7
    br #ipe_entry4

untrusted_ret:
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; IPE STUBS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; IPE 1
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
    cmp #1, r9
    jeq ocall_ret
    clr r6
    br #ecall_ret

undef_irq:
    reti


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; IPE 2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .sect ".ipe2_hw_entry", "a"
; single IPE entry point: routes call to function or return address
ipe_entry2:
    ; HW initializes the secure IPE stack to zero
    cmp #0x00, r1
    jne stack_initialized2
    mov #ipe2_base_stack, r1
stack_initialized2:
    ; entry idx=-1 is reserved for the special IRQ dispatch entry point
    cmp #-1, r7
    jeq irq_dispatch2

    ; if stack pointer is in the initial position, assume it's an entry call,
    ; not a return from an untrusted function
    cmp #ipe2_base_stack, r1
    jne ocall_ret2

    ; calling one of the entry points, not returning from an ocall
    ; r7 contains the index of the called function
    ; r12-r15 contain the arguments for the called function
    cmp r7, &max_ecall_index2
    jhs index_in_bounds2
    mov #0, r7  ; set index to 0 if it was out of bounds
index_in_bounds2:
    rla r7
    rla r7      ; r7 = 4*index -- each entry is 4 bytes
    mov ecall_table2(r7), r6
    call r6
    add #2, r7  ; get size of return argument
    mov.b ecall_table2(r7), r6

ecall_ret2:
    clear_argument_regs
    clear_secret_regs
    clr r7
    br #untrusted_ret

; securely call an untrusted function
; r7: address of untrusted function
; r6: bitmap of function arguments
ipe_ocall2:
    push_callee_save
    clear_argument_regs
    clear_secret_regs
    br #ipe_ocall_cont2

ocall_ret2:
    mov &__MPUIP2SEGB2, r4
    rla r4
    rla r4
    rla r4
    rla r4
    ; check whether padding number is saved (return from isr)
    mov -34(r4), r5
    cmp #0, r5
    jeq return_from_ocall2
return_from_isr2:
    mov #7, r6
    sub r5, r6
    add r6, r6
    add #nemesis_mitigation2, r6
    br r6

nemesis_mitigation2:
    nop
    nop
    nop
    nop
    nop
    nop
    nop

nemesis_ret2:
    mov #0, -34(r4)
    pop_all_regs
    reti

return_from_ocall2:
    pop_callee_save
    ret


; IPE dispatcher for handling interrupts during unprotected code execution
; r8: IRQ number
irq_dispatch2:
    cmp #14, r8
    jhs irq_dispatch_ret2
    rla r8      ; r8 = 2*index -- each entry is 2 bytes
    mov __ipe2_vectors_start(r8), r8

    ; setup a fake reti stack as we call this handler through SW
    push #irq_dispatch_ret2
    push r2
    br r8

irq_dispatch_ret2:
    cmp #1, r9
    jeq ocall_ret2
    clr r6
    br #ecall_ret2

undef_irq2:
    reti

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; IPE 3
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .sect ".ipe3_hw_entry", "a"
; single IPE entry point: routes call to function or return address
ipe_entry3:
    ; HW initializes the secure IPE stack to zero
    cmp #0x00, r1
    jne stack_initialized3
    mov #ipe3_base_stack, r1
stack_initialized3:
    ; entry idx=-1 is reserved for the special IRQ dispatch entry point
    cmp #-1, r7
    jeq irq_dispatch3

    ; if stack pointer is in the initial position, assume it's an entry call,
    ; not a return from an untrusted function
    cmp #ipe3_base_stack, r1
    jne ocall_ret3

    ; calling one of the entry points, not returning from an ocall
    ; r7 contains the index of the called function
    ; r12-r15 contain the arguments for the called function
    cmp r7, &max_ecall_index3
    jhs index_in_bounds3
    mov #0, r7  ; set index to 0 if it was out of bounds
index_in_bounds3:
    rla r7
    rla r7      ; r7 = 4*index -- each entry is 4 bytes
    mov ecall_table3(r7), r6
    call r6
    add #2, r7  ; get size of return argument
    mov.b ecall_table3(r7), r6

ecall_ret3:
    clear_argument_regs
    clear_secret_regs
    clr r7
    br #untrusted_ret

; securely call an untrusted function
; r7: address of untrusted function
; r6: bitmap of function arguments
ipe_ocall3:
    push_callee_save
    clear_argument_regs
    clear_secret_regs
    br #ipe_ocall_cont3

ocall_ret3:
    mov &__MPUIP3SEGB2, r4
    rla r4
    rla r4
    rla r4
    rla r4
    ; check whether padding number is saved (return from isr)
    mov -34(r4), r5
    cmp #0, r5
    jeq return_from_ocall3
return_from_isr3:
    mov #7, r6
    sub r5, r6
    add r6, r6
    add #nemesis_mitigation3, r6
    br r6

nemesis_mitigation3:
    nop
    nop
    nop
    nop
    nop
    nop
    nop

nemesis_ret3:
    mov #0, -34(r4)
    pop_all_regs
    reti

return_from_ocall3:
    pop_callee_save
    ret


; IPE dispatcher for handling interrupts during unprotected code execution
; r8: IRQ number
irq_dispatch3:
    cmp #14, r8
    jhs irq_dispatch_ret3
    rla r8      ; r8 = 2*index -- each entry is 2 bytes
    mov __ipe3_vectors_start(r8), r8

    ; setup a fake reti stack as we call this handler through SW
    push #irq_dispatch_ret3
    push r2
    br r8

irq_dispatch_ret3:
    cmp #1, r9
    jeq ocall_ret3
    clr r6
    br #ecall_ret3

undef_irq3:
    reti

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; IPE 4
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .sect ".ipe4_hw_entry", "a"
; single IPE entry point: routes call to function or return address
ipe_entry4:
    ; HW initializes the secure IPE stack to zero
    cmp #0x00, r1
    jne stack_initialized4
    mov #ipe4_base_stack, r1
stack_initialized4:
    ; entry idx=-1 is reserved for the special IRQ dispatch entry point
    cmp #-1, r7
    jeq irq_dispatch4

    ; if stack pointer is in the initial position, assume it's an entry call,
    ; not a return from an untrusted function
    cmp #ipe4_base_stack, r1
    jne ocall_ret4

    ; calling one of the entry points, not returning from an ocall
    ; r7 contains the index of the called function
    ; r12-r15 contain the arguments for the called function
    cmp r7, &max_ecall_index4
    jhs index_in_bounds4
    mov #0, r7  ; set index to 0 if it was out of bounds
index_in_bounds4:
    rla r7
    rla r7      ; r7 = 4*index -- each entry is 4 bytes
    mov ecall_table4(r7), r6
    call r6
    add #2, r7  ; get size of return argument
    mov.b ecall_table4(r7), r6

ecall_ret4:
    clear_argument_regs
    clear_secret_regs
    clr r7
    br #untrusted_ret

; securely call an untrusted function
; r7: address of untrusted function
; r6: bitmap of function arguments
ipe_ocall4:
    push_callee_save
    clear_argument_regs
    clear_secret_regs
    br #ipe_ocall_cont4

ocall_ret4:
    mov &__MPUIP4SEGB2, r4
    rla r4
    rla r4
    rla r4
    rla r4
    ; check whether padding number is saved (return from isr)
    mov -34(r4), r5
    cmp #0, r5
    jeq return_from_ocall4
return_from_isr4:
    mov #7, r6
    sub r5, r6
    add r6, r6
    add #nemesis_mitigation4, r6
    br r6

nemesis_mitigation4:
    nop
    nop
    nop
    nop
    nop
    nop
    nop

nemesis_ret4:
    mov #0, -34(r4)
    pop_all_regs
    reti

return_from_ocall4:
    pop_callee_save
    ret


; IPE dispatcher for handling interrupts during unprotected code execution
; r8: IRQ number
irq_dispatch4:
    cmp #14, r8
    jhs irq_dispatch_ret4
    rla r8      ; r8 = 2*index -- each entry is 2 bytes
    mov __ipe4_vectors_start(r8), r8

    ; setup a fake reti stack as we call this handler through SW
    push #irq_dispatch_ret4
    push r2
    br r8

irq_dispatch_ret4:
    cmp #1, r9
    jeq ocall_ret4
    clr r6
    br #ecall_ret4

undef_irq4:
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

    .sect ".ipe2_vectors", "a"
ipe_ivt2:
    .word undef_irq2
    .word undef_irq2
    .word undef_irq2
    .word undef_irq2
    .word undef_irq2
    .word undef_irq2
    .word undef_irq2
    .word undef_irq2
    .word undef_irq2
    .word undef_irq2
    .word undef_irq2
    .word undef_irq2
    .word undef_irq2
    .word undef_irq2
    .word undef_irq2
    .word undef_irq2

    .sect ".ipe3_vectors", "a"
ipe_ivt3:
    .word undef_irq3
    .word undef_irq3
    .word undef_irq3
    .word undef_irq3
    .word undef_irq3
    .word undef_irq3
    .word undef_irq3
    .word undef_irq3
    .word undef_irq3
    .word undef_irq3
    .word undef_irq3
    .word undef_irq3
    .word undef_irq3
    .word undef_irq3
    .word undef_irq3
    .word undef_irq3

    .sect ".ipe4_vectors", "a"
ipe_ivt4:
    .word undef_irq4
    .word undef_irq4
    .word undef_irq4
    .word undef_irq4
    .word undef_irq4
    .word undef_irq4
    .word undef_irq4
    .word undef_irq4
    .word undef_irq4
    .word undef_irq4
    .word undef_irq4
    .word undef_irq4
    .word undef_irq4
    .word undef_irq4
    .word undef_irq4
    .word undef_irq4
.endif
