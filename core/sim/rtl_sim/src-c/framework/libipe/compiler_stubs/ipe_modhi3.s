    .section ".ipe_func"
    .align 2
    .global __ipe___modhi3
    .type __ipe___modhi3,@function

__ipe___modhi3:
    call    #__ipe___divhi3
    mov     r14,    r15
    ret
    