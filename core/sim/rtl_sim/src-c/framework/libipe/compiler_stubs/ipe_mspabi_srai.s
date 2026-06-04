    .section ".ipe_func"
    .align 2
    .global __ipe___mspabi_srai
    .type __ipe___mspabi_srai,@function


loop:
    add	#-1, r13
    rra	r12	

__ipe___mspabi_srai:
    cmp	#0,	r13
    jnz	loop     
    ret