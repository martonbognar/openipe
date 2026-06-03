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

__irq_trampoline_call:
    ; prepare fake stack for ISR reti: r0, r2
    ; r0 return address (#ipe_entry) already pushed before
    push r2
    ; branch to ISR via untrusted IVT
    mov &__irq_num, r15
    add r15, r15
    clr &__irq_num
    br __vectors_start(r15)

__irq_trampoline_call2:
    ; prepare fake stack for ISR reti: r0, r2
    ; r0 return address (#ipe_entry) already pushed before
    push r2
    ; branch to ISR via untrusted IVT
    mov &__irq_num2, r15
    add r15, r15
    clr &__irq_num2
    br __vectors_start(r15)

__irq_trampoline_call3:
    ; prepare fake stack for ISR reti: r0, r2
    ; r0 return address (#ipe_entry) already pushed before
    push r2
    ; branch to ISR via untrusted IVT
    mov &__irq_num3, r15
    add r15, r15
    clr &__irq_num3
    br __vectors_start(r15)

__irq_trampoline_call4:
    ; prepare fake stack for ISR reti: r0, r2
    ; r0 return address (#ipe_entry) already pushed before
    push r2
    ; branch to ISR via untrusted IVT
    mov &__irq_num4, r15
    add r15, r15
    clr &__irq_num4
    br __vectors_start(r15)

    .sect ".data"
__irq_num:
    .word 0x0
__irq_num2:
    .word 0x0
__irq_num3:
    .word 0x0
__irq_num4:
    .word 0x0

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
    clr r6
    br #ecall_ret2

; IPE dispatcher for handling interrupts during protected code execution
; divert IPE execution to unprotected handler and back
ipe2_irq_trampoline_0:
    inc &__irq_num2
ipe2_irq_trampoline_1:
    inc &__irq_num2
ipe2_irq_trampoline_2:
    inc &__irq_num2
ipe2_irq_trampoline_3:
    inc &__irq_num2
ipe2_irq_trampoline_4:
    inc &__irq_num2
ipe2_irq_trampoline_5:
    inc &__irq_num2
ipe2_irq_trampoline_6:
    inc &__irq_num2
ipe2_irq_trampoline_7:
    inc &__irq_num2
ipe2_irq_trampoline_8:
    inc &__irq_num2
ipe2_irq_trampoline_9:
    inc &__irq_num2
ipe2_irq_trampoline_10:
    inc &__irq_num2
ipe2_irq_trampoline_11:
    inc &__irq_num2
ipe2_irq_trampoline_12:
    inc &__irq_num2
ipe2_irq_trampoline_13:
    inc &__irq_num2
ipe2_irq_trampoline_14:
    inc &__irq_num2
ipe2_irq_trampoline_15:
    inc &__irq_num2

    push r6
    push r7
    clr r6
    mov #__irq_trampoline_call2, r7
    call #ipe_ocall2

; call to ipe_ocall will return here
; continue interrupted IPE execution
ipe_irq_trampoline_reti2:
    pop r7
    pop r6
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
    clr r6
    br #ecall_ret3

; IPE dispatcher for handling interrupts during protected code execution
; divert IPE execution to unprotected handler and back
ipe3_irq_trampoline_0:
    inc &__irq_num3
ipe3_irq_trampoline_1:
    inc &__irq_num3
ipe3_irq_trampoline_2:
    inc &__irq_num3
ipe3_irq_trampoline_3:
    inc &__irq_num3
ipe3_irq_trampoline_4:
    inc &__irq_num3
ipe3_irq_trampoline_5:
    inc &__irq_num3
ipe3_irq_trampoline_6:
    inc &__irq_num3
ipe3_irq_trampoline_7:
    inc &__irq_num3
ipe3_irq_trampoline_8:
    inc &__irq_num3
ipe3_irq_trampoline_9:
    inc &__irq_num3
ipe3_irq_trampoline_10:
    inc &__irq_num3
ipe3_irq_trampoline_11:
    inc &__irq_num3
ipe3_irq_trampoline_12:
    inc &__irq_num3
ipe3_irq_trampoline_13:
    inc &__irq_num3
ipe3_irq_trampoline_14:
    inc &__irq_num3
ipe3_irq_trampoline_15:
    inc &__irq_num3

    push r6
    push r7
    clr r6
    mov #__irq_trampoline_call3, r7
    call #ipe_ocall3

; call to ipe_ocall will return here
; continue interrupted IPE execution
ipe_irq_trampoline_reti3:
    pop r7
    pop r6
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
    clr r6
    br #ecall_ret4

; IPE dispatcher for handling interrupts during protected code execution
; divert IPE execution to unprotected handler and back
ipe4_irq_trampoline_0:
    inc &__irq_num4
ipe4_irq_trampoline_1:
    inc &__irq_num4
ipe4_irq_trampoline_2:
    inc &__irq_num4
ipe4_irq_trampoline_3:
    inc &__irq_num4
ipe4_irq_trampoline_4:
    inc &__irq_num4
ipe4_irq_trampoline_5:
    inc &__irq_num4
ipe4_irq_trampoline_6:
    inc &__irq_num4
ipe4_irq_trampoline_7:
    inc &__irq_num4
ipe4_irq_trampoline_8:
    inc &__irq_num4
ipe4_irq_trampoline_9:
    inc &__irq_num4
ipe4_irq_trampoline_10:
    inc &__irq_num4
ipe4_irq_trampoline_11:
    inc &__irq_num4
ipe4_irq_trampoline_12:
    inc &__irq_num4
ipe4_irq_trampoline_13:
    inc &__irq_num4
ipe4_irq_trampoline_14:
    inc &__irq_num4
ipe4_irq_trampoline_15:
    inc &__irq_num4

    push r6
    push r7
    clr r6
    mov #__irq_trampoline_call4, r7
    call #ipe_ocall4

; call to ipe_ocall will return here
; continue interrupted IPE execution
ipe_irq_trampoline_reti4:
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

    .sect ".ipe2_vectors", "a"
ipe_ivt2:
    .word ipe2_irq_trampoline_0
    .word ipe2_irq_trampoline_1
    .word ipe2_irq_trampoline_2
    .word ipe2_irq_trampoline_3
    .word ipe2_irq_trampoline_4
    .word ipe2_irq_trampoline_5
    .word ipe2_irq_trampoline_6
    .word ipe2_irq_trampoline_7
    .word ipe2_irq_trampoline_8
    .word ipe2_irq_trampoline_9
    .word ipe2_irq_trampoline_10
    .word ipe2_irq_trampoline_11
    .word ipe2_irq_trampoline_12
    .word ipe2_irq_trampoline_13
    .word ipe2_irq_trampoline_14
    .word ipe2_irq_trampoline_15

    .sect ".ipe3_vectors", "a"
ipe_ivt3:
    .word ipe3_irq_trampoline_0
    .word ipe3_irq_trampoline_1
    .word ipe3_irq_trampoline_2
    .word ipe3_irq_trampoline_3
    .word ipe3_irq_trampoline_4
    .word ipe3_irq_trampoline_5
    .word ipe3_irq_trampoline_6
    .word ipe3_irq_trampoline_7
    .word ipe3_irq_trampoline_8
    .word ipe3_irq_trampoline_9
    .word ipe3_irq_trampoline_10
    .word ipe3_irq_trampoline_11
    .word ipe3_irq_trampoline_12
    .word ipe3_irq_trampoline_13
    .word ipe3_irq_trampoline_14
    .word ipe3_irq_trampoline_15

    .sect ".ipe4_vectors", "a"
ipe_ivt4:
    .word ipe4_irq_trampoline_0
    .word ipe4_irq_trampoline_1
    .word ipe4_irq_trampoline_2
    .word ipe4_irq_trampoline_3
    .word ipe4_irq_trampoline_4
    .word ipe4_irq_trampoline_5
    .word ipe4_irq_trampoline_6
    .word ipe4_irq_trampoline_7
    .word ipe4_irq_trampoline_8
    .word ipe4_irq_trampoline_9
    .word ipe4_irq_trampoline_10
    .word ipe4_irq_trampoline_11
    .word ipe4_irq_trampoline_12
    .word ipe4_irq_trampoline_13
    .word ipe4_irq_trampoline_14
    .word ipe4_irq_trampoline_15
.endif
