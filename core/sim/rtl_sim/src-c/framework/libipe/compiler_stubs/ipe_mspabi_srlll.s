    .section ".ipe_func"
    .align 2
    .global __ipe___mspabi_srlll
    .type __ipe___mspabi_srll,@function
		

__ipe___mspabi_srlll:
    mov	r11, r15	
    mov	r12, r11
    mov	r10, r14
    mov	r9,	r13	
    mov	r8,	r12	
    cmp	#0,	r11
    jnz	loop
    ret			
loop:
    clrc			
    rrc	r15	
    rrc	r14	
    rrc	r13		
    rrc	r12		
    add	#-1, r11	
    jnz	loop
    ret
    