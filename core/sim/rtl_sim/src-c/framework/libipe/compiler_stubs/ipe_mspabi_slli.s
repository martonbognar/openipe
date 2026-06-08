    .section ".ipe_func"
    .align 2
    .global __ipe___mspabi_slli
    .type __ipe___mspabi_slli,@function

loop:
    add	#-1, r13
    rla	r12		

__ipe___mspabi_slli:
    cmp	#0,	r13	
    jnz	loop
    ret
    