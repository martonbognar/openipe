    .section ".ipe_func"
    .align 2
    .global __ipe___mspabi_srli
    .global __ipe___mspabi_srli_15
    .global __ipe___mspabi_srli_14
    .global __ipe___mspabi_srli_13
    .global __ipe___mspabi_srli_12
    .global __ipe___mspabi_srli_11
    .global __ipe___mspabi_srli_10
    .global __ipe___mspabi_srli_9
    .global __ipe___mspabi_srli_8
    .global __ipe___mspabi_srli_7
    .global __ipe___mspabi_srli_6
    .global __ipe___mspabi_srli_5
    .global __ipe___mspabi_srli_4
    .global __ipe___mspabi_srli_3
    .global __ipe___mspabi_srli_2
    .global __ipe___mspabi_srli_1

    .type __ipe___mspabi_srli_15,@function
    .type __ipe___mspabi_srli_14,@function
    .type __ipe___mspabi_srli_13,@function
    .type __ipe___mspabi_srli_12,@function
    .type __ipe___mspabi_srli_11,@function
    .type __ipe___mspabi_srli_10,@function
    .type __ipe___mspabi_srli_9,@function
    .type __ipe___mspabi_srli_8,@function
    .type __ipe___mspabi_srli_7,@function
    .type __ipe___mspabi_srli_6,@function
    .type __ipe___mspabi_srli_5,@function
    .type __ipe___mspabi_srli_4,@function
    .type __ipe___mspabi_srli_3,@function
    .type __ipe___mspabi_srli_2,@function
    .type __ipe___mspabi_srli_1,@function
    .type __ipe___mspabi_srli,@function


__ipe___mspabi_srli_15:
    clrc			
    rrc	r12
__ipe___mspabi_srli_14:
    clrc			
    rrc	r12
__ipe___mspabi_srli_13:
    clrc			
    rrc	r12
__ipe___mspabi_srli_12:
    clrc			
    rrc	r12
__ipe___mspabi_srli_11:
    clrc			
    rrc	r12
__ipe___mspabi_srli_10:
    clrc			
    rrc	r12
__ipe___mspabi_srli_9:
    clrc			
    rrc	r12
__ipe___mspabi_srli_8:
    clrc			
    rrc	r12
__ipe___mspabi_srli_7:
    clrc			
    rrc	r12
__ipe___mspabi_srli_6:
    clrc			
    rrc	r12
__ipe___mspabi_srli_5:
    clrc			
    rrc	r12
__ipe___mspabi_srli_4:
    clrc			
    rrc	r12
__ipe___mspabi_srli_3:
    clrc			
    rrc	r12
__ipe___mspabi_srli_2:
    clrc			
    rrc	r12
__ipe___mspabi_srli_1:
    clrc			
    rrc	r12
    ret 
		

loop:
    add	#-1, r13	
    clrc			
    rrc	r12	
__ipe___mspabi_srli:
    cmp	#0,	r13
    jnz	loop  
    ret
    