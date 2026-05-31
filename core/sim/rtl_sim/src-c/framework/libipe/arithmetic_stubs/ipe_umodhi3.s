    .section ".ipe_func"
    .align 2
    .global __ipe___umodhi3
    .type __ipe___umodhi3,@function

__ipe___umodhi3:
    call    #__ipe___udivhi3
    mov     r14,    r15
    ret