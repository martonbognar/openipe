    .section ".ipe_func"
    .align 2
    .global __ipe___mspabi_srai
    .global __ipe___mspabi_srai_15
    .global __ipe___mspabi_srai_14
    .global __ipe___mspabi_srai_13
    .global __ipe___mspabi_srai_12
    .global __ipe___mspabi_srai_11
    .global __ipe___mspabi_srai_10
    .global __ipe___mspabi_srai_9
    .global __ipe___mspabi_srai_8
    .global __ipe___mspabi_srai_7
    .global __ipe___mspabi_srai_6
    .global __ipe___mspabi_srai_5
    .global __ipe___mspabi_srai_4
    .global __ipe___mspabi_srai_3
    .global __ipe___mspabi_srai_2
    .global __ipe___mspabi_srai_1

    .type __ipe___mspabi_srai_15,@function
    .type __ipe___mspabi_srai_14,@function
    .type __ipe___mspabi_srai_13,@function
    .type __ipe___mspabi_srai_12,@function
    .type __ipe___mspabi_srai_11,@function
    .type __ipe___mspabi_srai_10,@function
    .type __ipe___mspabi_srai_9,@function
    .type __ipe___mspabi_srai_8,@function
    .type __ipe___mspabi_srai_7,@function
    .type __ipe___mspabi_srai_6,@function
    .type __ipe___mspabi_srai_5,@function
    .type __ipe___mspabi_srai_4,@function
    .type __ipe___mspabi_srai_3,@function
    .type __ipe___mspabi_srai_2,@function
    .type __ipe___mspabi_srai_1,@function
    .type __ipe___mspabi_srai,@function


__ipe___mspabi_srai_15:
    rra	r12
__ipe___mspabi_srai_14:
    rra	r12
__ipe___mspabi_srai_13:
    rra	r12
__ipe___mspabi_srai_12:
    rra	r12
__ipe___mspabi_srai_11:
    rra	r12
__ipe___mspabi_srai_10:
    rra	r12
__ipe___mspabi_srai_9:
    rra	r12
__ipe___mspabi_srai_8:
    rra	r12
__ipe___mspabi_srai_7:
    rra	r12
__ipe___mspabi_srai_6:
    rra	r12
__ipe___mspabi_srai_5:
    rra	r12
__ipe___mspabi_srai_4:
    rra	r12
__ipe___mspabi_srai_3:
    rra	r12
__ipe___mspabi_srai_2:
    rra	r12		
__ipe___mspabi_srai_1:
    rra	r12		
    ret

loop:
    add	#-1, r13
    rra	r12	

__ipe___mspabi_srai:
    cmp	#0,	r13
    jnz	loop     
    ret
    