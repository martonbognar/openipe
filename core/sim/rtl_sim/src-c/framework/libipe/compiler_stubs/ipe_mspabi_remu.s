    .section ".ipe_func"
    .align 2
    .global __ipe___mspabi_remu
    .type __ipe___mspabi_remu,@function

__ipe___mspabi_remu:
    call    #__ipe___mspabi_divu
    mov     r13,    r12
    ret
    