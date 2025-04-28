#ifndef IPE_SUPPORT_H_
#define IPE_SUPPORT_H_

// hardcoded <stdint.h> because the preprocessor struggles with it otherwise
typedef   signed char    int8_t;
typedef unsigned char   uint8_t;
typedef          int    int16_t;
typedef unsigned int   uint16_t;
typedef          long   int32_t;
typedef unsigned long  uint32_t;
typedef          long long  int64_t;
typedef unsigned long long uint64_t;

#define IPE_ENTRY __attribute__((section (".ipe_entry")))
#define IPE_FUNC __attribute__((section (".ipe_func")))
#define IPE_VAR __attribute__((section (".ipe_vars")))
#define IPE_CONST __attribute__((section (".ipe_const")))
#define IPE_ISR __attribute__((section (".ipe:_isr")))

#define IPE_MPUIPLOCK           0x0080
#define IPE_MPUIPENA            0x0040
#define IPE_MPUIPPUC            0x0020

typedef struct
{
    uint16_t ipc0 ;
    uint8_t *ipb2 ;
    uint8_t *ipb1 ;
    uint16_t check ;
} ipe_init_struct_t; // this struct should be placed inside IPB1/IPB2 boundaries

typedef struct { \
    /* IPE signature valid flag */
    uint16_t ipe_sig_valid;
    /* Source for pointer (nibble address) to MPU IPE structure */
    uint16_t ipe_struct_ptr_src;
} ipe_meta_struct_t;

/*
 * We can't statically initialize this in C due to pointer arithmetic.
 * The address of these symbols is the value given in the linker script
 * See https://stackoverflow.com/a/43852847
 */
extern uint8_t __ipe_start_shift, __ipe_end_shift, __ipe_struct_shift, __ipe_checksum;

#define DECLARE_IPE_META \
    ipe_meta_struct_t __attribute__((section (".ipe_meta"))) ipe_meta_struct = { \
        .ipe_sig_valid = 0xAAAA, \
        .ipe_struct_ptr_src = (uint16_t) &__ipe_struct_shift, \
    };

#define DECLARE_IPE_STRUCT \
     ipe_init_struct_t __attribute__((section (".ipestruct"))) ipe_init_struct = { \
        .ipc0  = IPE_MPUIPLOCK | IPE_MPUIPENA, \
        .ipb2  = &__ipe_end_shift, \
        .ipb1  = &__ipe_start_shift, \
        .check = (uint16_t) &__ipe_checksum, \
     }; \
    DECLARE_IPE_META

int outside_IPE_segment(char* ptr);
int constant_time_cmp(const unsigned char *x_, const unsigned char *y_, const unsigned int n);

#undef always_inline
#define always_inline static inline __attribute__((always_inline))

/*
 * HACK: include this as a weak symbol here so it is included in the symbol table and we can
 * fixup any relocations, but discard this unused dummy wrapper at link time..
 */
void __attribute__((weak)) IPE_FUNC *__ipe_memset(void *ptr, int value, int num); \
void __attribute__((weak)) __attribute__((section(".discard"))) __wrapper_ipe_memset(void *ptr, int value, int num) \
{ \
    __ipe_memset(ptr, value, num); \
}

#endif /* IPE_SUPPORT_H_ */
