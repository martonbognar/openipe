    .section ".ipe_func"
    .align 2
    .global __ipe___mspabi_srll
    .type __ipe___mspabi_srll,@function
		

loop:
    add	#-1, r14
    clrc			
    rrc	r13		
    rrc	r12		
__ipe___mspabi_srll:
    cmp	#0,	r14
    jnz	loop
    ret
    