    .global ipe_entry
    .global ipe_ocall

    .sect ".ipe_func"

    ; stub for all ocalls in IPE, stub:
    ;   sets r6 to number of registers used as arguments
    ;   sets r7 to address of unprotected function
    ; r6 and r7 used by "ipe_ocall" stub in ipe_stubs.s

    .global __ipe_ocall_ipe_dummy2_outside
    .global __ipe_ocall_ipe_dummy2_outside_stub
__ipe_ocall_ipe_dummy2_outside_stub:
    push r6
    push r7
    mov #0b00001000, r6
    mov #__ipe_ocall_ipe_dummy2_outside, r7
    call #ipe_ocall
    pop r7
    pop r6
    ret

    .global __ipe_ocall_ipe_dummy2_outside2
    .global __ipe_ocall_ipe_dummy2_outside2_stub
__ipe_ocall_ipe_dummy2_outside2_stub:
    push r6
    push r7
    mov #0b00001000, r6
    mov #__ipe_ocall_ipe_dummy2_outside2, r7
    call #ipe_ocall
    pop r7
    pop r6
    ret


    .sect ".text"

    ; stub for all entry functions in IPE, stub:
    ;   sets r7 to the index of the entry function in the entry function table (see write_table.py)
    ; r7 used by "ipe_entry" stub in ipe_stubs.s

    .global ipe_func
ipe_func:
    push r7
    mov #0, r7
    call #ipe_entry
    pop r7
    ret

    .global another_entry
another_entry:
    push r7
    mov #1, r7
    call #ipe_entry
    pop r7
    ret

    .global ipe_func2
ipe_func2:
    push r7
    mov #2, r7
    call #ipe_entry
    pop r7
    ret
