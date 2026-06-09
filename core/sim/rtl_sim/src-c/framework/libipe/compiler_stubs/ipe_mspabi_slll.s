    .section ".ipe_func"
    .align 2
    .global __ipe___mspabi_slll
    .global __ipe___mspabi_slll_15
    .global __ipe___mspabi_slll_14
    .global __ipe___mspabi_slll_13
    .global __ipe___mspabi_slll_12
    .global __ipe___mspabi_slll_11
    .global __ipe___mspabi_slll_10
    .global __ipe___mspabi_slll_9
    .global __ipe___mspabi_slll_8
    .global __ipe___mspabi_slll_7
    .global __ipe___mspabi_slll_6
    .global __ipe___mspabi_slll_5
    .global __ipe___mspabi_slll_4
    .global __ipe___mspabi_slll_3
    .global __ipe___mspabi_slll_2
    .global __ipe___mspabi_slll_1

    .type __ipe___mspabi_slll_15,@function
    .type __ipe___mspabi_slll_14,@function
    .type __ipe___mspabi_slll_13,@function
    .type __ipe___mspabi_slll_12,@function
    .type __ipe___mspabi_slll_11,@function
    .type __ipe___mspabi_slll_10,@function
    .type __ipe___mspabi_slll_9,@function
    .type __ipe___mspabi_slll_8,@function
    .type __ipe___mspabi_slll_7,@function
    .type __ipe___mspabi_slll_6,@function
    .type __ipe___mspabi_slll_5,@function
    .type __ipe___mspabi_slll_4,@function
    .type __ipe___mspabi_slll_3,@function
    .type __ipe___mspabi_slll_2,@function
    .type __ipe___mspabi_slll_1,@function
    .type __ipe___mspabi_slll,@function


__ipe___mspabi_slll_15:			
    rla	r13
    rlc	r12
__ipe___mspabi_slll_14:			
    rla	r13
    rlc	r12
__ipe___mspabi_slll_13:			
    rla	r13
    rlc	r12
__ipe___mspabi_slll_12:			
    rla	r13
    rlc	r12
__ipe___mspabi_slll_11:			
    rla	r13
    rlc	r12
__ipe___mspabi_slll_10:			
    rla	r13
    rlc	r12
__ipe___mspabi_slll_9:			
    rla	r13
    rlc	r12
__ipe___mspabi_slll_8:			
    rla	r13
    rlc	r12
__ipe___mspabi_slll_7:			
    rla	r13
    rlc	r12
__ipe___mspabi_slll_6:			
    rla	r13
    rlc	r12
__ipe___mspabi_slll_5:			
    rla	r13
    rlc	r12
__ipe___mspabi_slll_4:			
    rla	r13
    rlc	r12
__ipe___mspabi_slll_3:			
    rla	r13
    rlc	r12
__ipe___mspabi_slll_2:			
    rla	r13
    rlc	r12
__ipe___mspabi_slll_1:			
    rla	r13
    rlc	r12
    ret

loop:
    add	#-1, r14
    rla	r12	
    rlc	r13	

__ipe___mspabi_slll:
    cmp	#0,	r14	
    jnz	loop  
    ret
    