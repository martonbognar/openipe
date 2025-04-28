    .global ecall_table
    .global max_ecall_index
    .sect ".ipe_const"
    .align 2

    ; table to register address and number of registers used as argument for every entry function
    ; table consulted at runtime by "ipe_entry" stub in ipe_stubs.s
ecall_table:

    .global attest_internal
    .word attest_internal
    .word 0x8


max_ecall_index:
    .word 0