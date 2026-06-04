    .section ".ipe_func"
    .align 2
    .global __ipe___mspabi_divi
    .type __ipe___mspabi_divi,@function

__ipe___mspabi_divi:
    clr     r11
    tst     r12
    jge     1f
    mov     #3, r11
    inv     r12
    inc     r12
1:  tst     r13
    jge     2f
    xor.b   #1, r11
    inv     r13
    inc     r13
2:  push    r11
    call    #__ipe___mspabi_divu
    pop     r11
    bit.b   #2, r11
    jz      3f
    inv     r13
    inc     r13
3:  bit.b   #1, r11
    jz      4f
    inv     r12
    inc     r12
4:  ret
