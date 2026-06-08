    .section ".ipe_func"
    .align 2
    .global __ipe___mspabi_sllll
    .type __ipe___mspabi_sllll,@function

__ipe___mspabi_sllll:
    mov	r11, r15	
    mov	r12, r11	
    mov	r10, r14	
    mov	r9,	r13	
    mov	r8,	r12	
    cmp	#0,	r11
    jnz	loop 
    ret			

loop:
    rla	r12		
    rlc	r13		
    rlc	r14		
    rlc	r15		
    add	#-1, r11	
    jnz	loop
    ret
    