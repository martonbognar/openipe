    .section ".ipe_func"
    .align 2
    .global __ipe___udivhi3
    .type __ipe___udivhi3,@function

__ipe___udivhi3:
    mov.b   #16,    r12
    mov     r14,    r13
    clr     r14
1:  rla     r15
    rlc     r14
    cmp     r13,    r14
    jnc     2f
    sub     r13,    r14
    bis     #1,     r15
2:  dec     r12
    jnz     1b
    ret