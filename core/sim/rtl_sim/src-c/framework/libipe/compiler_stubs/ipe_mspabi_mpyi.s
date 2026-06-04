    .section ".ipe_func"
    .align 2
    .global __ipe___mspabi_mpyi
    .type __ipe___mspabi_mpyi,@function

    ; \arg r12: a
    ; \arg r13: b
    ; \ret r12: a*b
    ; \note: clobbers r11
__ipe___mspabi_mpyi:
    mov     r12, r11
    clr     r12
1:  tst     r13
    jz      3f
    clrc
    rrc     r11
    jnc     2f
    add     r13, r12
2:  rla     r13
    tst     r11
    jnz     1b
3:  ret
