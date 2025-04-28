    .global ipe_entry
    .global ipe_ocall

    .sect ".ipe_func"

    ; stub for all ocalls in IPE, stub:
    ;   sets r6 to number of registers used as arguments
    ;   sets r7 to address of unprotected function
    ; r6 and r7 used by "ipe_ocall" stub in ipe_stubs.s

    .global signal_done
    .global signal_done_stub
signal_done_stub:
    push r6
    push r7
    mov #0b00000000, r6
    mov #signal_done, r7
    call #ipe_ocall
    pop r7
    pop r6
    ret


    .sect ".text"

    ; stub for all entry functions in IPE, stub:
    ;   sets r7 to the index of the entry function in the entry function table (see write_table.py)
    ; r7 used by "ipe_entry" stub in ipe_stubs.s

    .global attest
attest:
    push r7
    mov #0, r7
    call #ipe_entry
    pop r7
    ret
