    .section ".ipe_func"
    .align 2
    .global __ipe_memset
    .type __ipe_memset,@function

    # void *memset(void s[.n], int c, size_t n);
    # \in  r12: s
    # \in  r13: c
    # \in  r14: n
    # \out r12: s
__ipe_memset:
    add	r12, r14
    mov	r12, r15
l1:
    cmp	r14, r15	
    jnz	l2  
    ret			
l2:
    inc	r15
    mov.b	r13, -1(r15)
    jmp	l1 

