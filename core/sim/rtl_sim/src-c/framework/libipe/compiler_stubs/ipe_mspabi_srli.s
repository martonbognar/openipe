    .section ".ipe_func"
    .align 2
    .global __ipe___mspabi_srli
    .type __ipe___mspabi_srli,@function
		

loop:
    add	#-1, r13	
    clrc			
    rrc	r12	
__ipe___mspabi_srli:
    cmp	#0,	r13
    jnz	loop  
    ret