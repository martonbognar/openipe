    .section ".ipe_func"
    .align 2
    .global __ipe___mspabi_remi
    .type __ipe___mspabi_remi,@function

__ipe___mspabi_remi:
    call    #__ipe___mspabi_divi
    mov     r13,    r12
    ret
    