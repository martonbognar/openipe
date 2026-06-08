    .section ".ipe_func"
    .align 2
    .global __ipe___mspabi_slll
    .type __ipe___mspabi_slll,@function

loop:
    add	#-1, r14
    rla	r12	
    rlc	r13	

__ipe___mspabi_slll:
    cmp	#0,	r14	
    jnz	loop  
    ret
    