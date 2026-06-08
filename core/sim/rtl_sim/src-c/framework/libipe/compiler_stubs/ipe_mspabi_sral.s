    .section ".ipe_func"
    .align 2
    .global __ipe___mspabi_sral
    .type __ipe___mspabi_sral,@function
		

loop:
    add	#-1, r14
    rra	r13
    rrc	r12		
__ipe___mspabi_sral:
    cmp	#0,	r14	
    jnz loop
    ret
    