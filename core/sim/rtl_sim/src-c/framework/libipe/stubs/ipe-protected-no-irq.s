.include "../../bin/ipe_macros.asm"

    ;; exported symbols
    .global ipe_ocall
    .global ipe_entry

/*
    .global ipe_ocall2
    .global ipe_entry2
    .global ipe_ocall3
    .global ipe_entry3
    .global ipe_ocall4
    .global ipe_entry4

*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; UNPROTECTED STUBS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .sect ".text"

; address of untrusted function passed in r7
ipe_ocall_cont:
    ; enable interrupts once outside the enclave
    eint_all
    call r7
    br #ipe_entry

/*

ipe_ocall_cont2:
    ; enable interrupts once outside the enclave
    eint_all
    call r7
    br #ipe_entry2

ipe_ocall_cont3:
    ; enable interrupts once outside the enclave
    eint_all
    call r7
    br #ipe_entry3

ipe_ocall_cont4:
    ; enable interrupts once outside the enclave
    eint_all
    call r7
    br #ipe_entry4

*/

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
    ; disable interrupts from software
    dint_all
    ; HW initializes the secure IPE stack to zero
    cmp #0x00, r1
    jne stack_initialized
    mov #ipe_base_stack, r1
stack_initialized:
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

/*

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; IPE 2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .sect ".ipe2_hw_entry", "a"
; single IPE entry point: routes call to function or return address
ipe_entry2:
    ; disable interrupts from software
    dint_all
    ; HW initializes the secure IPE stack to zero
    cmp #0x00, r1
    jne stack_initialized2
    mov #ipe2_base_stack, r1
stack_initialized2:
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
    br #ipe2_ocall_cont

ocall_ret2:
    pop_callee_save
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; IPE 3
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .sect ".ipe3_hw_entry", "a"
; single IPE entry point: routes call to function or return address
ipe_entry3:
    ; disable interrupts from software
    dint_all
    ; HW initializes the secure IPE stack to zero
    cmp #0x00, r1
    jne stack_initialized3
    mov #ipe3_base_stack, r1
stack_initialized3:
    ; if stack pointer is in the initial position, assume it's an entry call,
    ; not a return from an untrusted function
    cmp #ipe3_base_stack, r1
    jne ocall_ret

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; IPE 4
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .sect ".ipe4_hw_entry", "a"
; single IPE entry point: routes call to function or return address
ipe_entry4:
    ; disable interrupts from software
    dint_all
    ; HW initializes the secure IPE stack to zero
    cmp #0x00, r1
    jne stack_initialized4
    mov #ipe4_base_stack, r1
stack_initialized4:
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

*/