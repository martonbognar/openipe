    .section ".ipe_func"
    .align 2
    .global __ipe___mspabi_divu
    .type __ipe___mspabi_divu,@function

__ipe___mspabi_divu:
    mov.b   #16,    r14
    mov     r13,    r15
    clr     r13
1:  rla     r12
    rlc     r13
    cmp     r15,    r13
    jnc     2f
    sub     r15,    r13
    bis     #1,     r12
2:  dec     r14
    jnz     1b
    ret
    