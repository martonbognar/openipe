    .section ".ipe_func"
    .align 2
    .global __ipe___mspabi_slli
    .global __ipe___mspabi_slli_15
    .global __ipe___mspabi_slli_14
    .global __ipe___mspabi_slli_13
    .global __ipe___mspabi_slli_12
    .global __ipe___mspabi_slli_11
    .global __ipe___mspabi_slli_10
    .global __ipe___mspabi_slli_9
    .global __ipe___mspabi_slli_8
    .global __ipe___mspabi_slli_7
    .global __ipe___mspabi_slli_6
    .global __ipe___mspabi_slli_5
    .global __ipe___mspabi_slli_4
    .global __ipe___mspabi_slli_3
    .global __ipe___mspabi_slli_2
    .global __ipe___mspabi_slli_1

    .type __ipe___mspabi_slli_15,@function
    .type __ipe___mspabi_slli_14,@function
    .type __ipe___mspabi_slli_13,@function
    .type __ipe___mspabi_slli_12,@function
    .type __ipe___mspabi_slli_11,@function
    .type __ipe___mspabi_slli_10,@function
    .type __ipe___mspabi_slli_9,@function
    .type __ipe___mspabi_slli_8,@function
    .type __ipe___mspabi_slli_7,@function
    .type __ipe___mspabi_slli_6,@function
    .type __ipe___mspabi_slli_5,@function
    .type __ipe___mspabi_slli_4,@function
    .type __ipe___mspabi_slli_3,@function
    .type __ipe___mspabi_slli_2,@function
    .type __ipe___mspabi_slli_1,@function
    .type __ipe___mspabi_slli,@function


__ipe___mspabi_slli_15:			
    rla	r12
__ipe___mspabi_slli_14:			
    rla	r12
__ipe___mspabi_slli_13:			
    rla	r12
__ipe___mspabi_slli_12:			
    rla	r12
__ipe___mspabi_slli_11:			
    rla	r12
__ipe___mspabi_slli_10:			
    rla	r12
__ipe___mspabi_slli_9:			
    rla	r12
__ipe___mspabi_slli_8:			
    rla	r12
__ipe___mspabi_slli_7:			
    rla	r12
__ipe___mspabi_slli_6:			
    rla	r12
__ipe___mspabi_slli_5:			
    rla	r12
__ipe___mspabi_slli_4:			
    rla	r12
__ipe___mspabi_slli_3:			
    rla	r12
__ipe___mspabi_slli_2:			
    rla	r12
__ipe___mspabi_slli_1:			
    rla	r12
    ret 

loop:
    add	#-1, r13
    rla	r12		

__ipe___mspabi_slli:
    cmp	#0,	r13	
    jnz	loop
    ret
    