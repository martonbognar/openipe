    .section ".ipe_func"
    .align 2
    .global __ipe_memset
    .type __ipe_memset,@function

    # void *memset(void s[.n], int c, size_t n);
    # \in  r15: s
    # \in  r14: c
    # \in  r13: n
    # \out r15: s
__ipe_memset:
    mov     r15, r12
1:
    tst     r13
    jz      2f
    mov.b   r14, @r15
    add     #1, r15
    add     #-1, r13
    jmp     1b
2:
    mov     r12, r15
    ret
