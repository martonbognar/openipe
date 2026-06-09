    .section ".ipe_func"
    .align 2
    .global __ipe___mspabi_srll
    .global __ipe___mspabi_srll_15
    .global __ipe___mspabi_srll_14
    .global __ipe___mspabi_srll_13
    .global __ipe___mspabi_srll_12
    .global __ipe___mspabi_srll_11
    .global __ipe___mspabi_srll_10
    .global __ipe___mspabi_srll_9
    .global __ipe___mspabi_srll_8
    .global __ipe___mspabi_srll_7
    .global __ipe___mspabi_srll_6
    .global __ipe___mspabi_srll_5
    .global __ipe___mspabi_srll_4
    .global __ipe___mspabi_srll_3
    .global __ipe___mspabi_srll_2
    .global __ipe___mspabi_srll_1

    .type __ipe___mspabi_srll_15,@function
    .type __ipe___mspabi_srll_14,@function
    .type __ipe___mspabi_srll_13,@function
    .type __ipe___mspabi_srll_12,@function
    .type __ipe___mspabi_srll_11,@function
    .type __ipe___mspabi_srll_10,@function
    .type __ipe___mspabi_srll_9,@function
    .type __ipe___mspabi_srll_8,@function
    .type __ipe___mspabi_srll_7,@function
    .type __ipe___mspabi_srll_6,@function
    .type __ipe___mspabi_srll_5,@function
    .type __ipe___mspabi_srll_4,@function
    .type __ipe___mspabi_srll_3,@function
    .type __ipe___mspabi_srll_2,@function
    .type __ipe___mspabi_srll_1,@function
    .type __ipe___mspabi_srll,@function


__ipe___mspabi_srll_15:
    clrc			
    rrc	r13
    rrc	r12
__ipe___mspabi_srll_14:
    clrc			
    rrc	r13
    rrc	r12
__ipe___mspabi_srll_13:
    clrc			
    rrc	r13
    rrc	r12
__ipe___mspabi_srll_12:
    clrc			
    rrc	r13
    rrc	r12
__ipe___mspabi_srll_11:
    clrc			
    rrc	r13
    rrc	r12
__ipe___mspabi_srll_10:
    clrc			
    rrc	r13
    rrc	r12
__ipe___mspabi_srll_9:
    clrc			
    rrc	r13
    rrc	r12
__ipe___mspabi_srll_8:
    clrc			
    rrc	r13
    rrc	r12
__ipe___mspabi_srll_7:
    clrc			
    rrc	r13
    rrc	r12
__ipe___mspabi_srll_6:
    clrc			
    rrc	r13
    rrc	r12
__ipe___mspabi_srll_5:
    clrc			
    rrc	r13
    rrc	r12
__ipe___mspabi_srll_4:
    clrc			
    rrc	r13
    rrc	r12
__ipe___mspabi_srll_3:
    clrc			
    rrc	r13
    rrc	r12
__ipe___mspabi_srll_2:
    clrc			
    rrc	r13
    rrc	r12
__ipe___mspabi_srll_1:
    clrc			
    rrc	r13
    rrc	r12
    ret    

loop:
    add	#-1, r14
    clrc			
    rrc	r13		
    rrc	r12		
__ipe___mspabi_srll:
    cmp	#0,	r14
    jnz	loop
    ret
    