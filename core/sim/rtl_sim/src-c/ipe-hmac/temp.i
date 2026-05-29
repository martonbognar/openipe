int attest(void);
int signal_done_stub(int);
typedef signed char int8_t;
typedef unsigned char uint8_t;
typedef int int16_t;
typedef unsigned int uint16_t;
typedef long int32_t;
typedef unsigned long uint32_t;
typedef long long int64_t;
typedef unsigned long long uint64_t;
typedef int8_t int_least8_t;
typedef uint8_t uint_least8_t;
typedef int16_t int_least16_t;
typedef uint16_t uint_least16_t;
typedef int32_t int_least32_t;
typedef uint32_t uint_least32_t;
typedef int64_t int_least64_t;
typedef uint64_t uint_least64_t;
typedef signed char int8_t;
typedef unsigned char uint8_t;
typedef int int16_t;
typedef unsigned int uint16_t;
typedef long int32_t;
typedef unsigned long uint32_t;
typedef long long int64_t;
typedef unsigned long long uint64_t;
typedef struct 
{
  uint16_t ipc0;
  uint8_t *ipb2;
  uint8_t *ipb1;
  uint16_t check;
} ipe_init_struct_t;
typedef struct 
{
  uint16_t ipe_sig_valid;
  uint16_t ipe_struct_ptr_src;
} ipe_meta_struct_t;
extern uint8_t __ipe_start_shift;
extern uint8_t __ipe_end_shift;
extern uint8_t __ipe_struct_shift;
extern uint8_t __ipe_checksum;
int outside_IPE_segment(char *ptr);
int constant_time_cmp(const unsigned char *x_, const unsigned char *y_, const unsigned int n);
 __attribute__((weak))  __attribute__((section(".ipe_func"))) void *__ipe_memset(void *ptr, int value, int num);
 __attribute__((weak))  __attribute__((section(".discard"))) void __wrapper_ipe_memset(void *ptr, int value, int num)
{
  __ipe_memset(ptr, value, num);
}

 __attribute__((section(".ipestruct"))) ipe_init_struct_t ipe_init_struct = {.ipc0 = 0x0080 | 0x0040, .ipb2 = & __ipe_end_shift, .ipb1 = & __ipe_start_shift, .check = (uint16_t) (& __ipe_checksum)};
 __attribute__((section(".ipe_meta"))) ipe_meta_struct_t ipe_meta_struct = {.ipe_sig_valid = 0xAAAA, .ipe_struct_ptr_src = (uint16_t) (& __ipe_struct_shift)};
int signal_done(int);
extern uint8_t mac_region[];
extern int exit_success;
extern int exit_failure;
typedef int exit_code;
void print_string(const char *s);
void print_bytes(uint8_t *b, uint32_t len);
void kremlinit_globals(void);
typedef uint64_t FStar_UInt64_t;
typedef uint64_t FStar_UInt64_t_;
typedef int64_t FStar_Int64_t;
typedef int64_t FStar_Int64_t_;
typedef uint32_t FStar_UInt32_t;
typedef uint32_t FStar_UInt32_t_;
typedef int32_t FStar_Int32_t;
typedef int32_t FStar_Int32_t_;
typedef uint16_t FStar_UInt16_t;
typedef uint16_t FStar_UInt16_t_;
typedef int16_t FStar_Int16_t;
typedef int16_t FStar_Int16_t_;
typedef uint8_t FStar_UInt8_t;
typedef uint8_t FStar_UInt8_t_;
typedef int8_t FStar_Int8_t;
typedef int8_t FStar_Int8_t_;
void WasmSupport_check_buffer_size(uint32_t s);;
typedef void *FStar_Seq_Base_seq;
typedef void *Prims_prop;
typedef void *FStar_HyperStack_mem;
typedef void *FStar_Set_set;
typedef void *Prims_st_pre_h;
typedef void *FStar_Heap_heap;
typedef void *Prims_all_pre_h;
typedef void *FStar_TSet_set;
typedef void *Prims_list;
typedef void *FStar_Map_t;
typedef void *FStar_UInt63_t_;
typedef void *FStar_Int63_t_;
typedef void *FStar_UInt63_t;
typedef void *FStar_Int63_t;
typedef void *FStar_UInt_uint_t;
typedef void *FStar_Int_int_t;
typedef void *FStar_HyperStack_stackref;
typedef void *FStar_Bytes_bytes;
typedef void *FStar_HyperHeap_rid;
typedef void *FStar_Heap_aref;
typedef void *FStar_Monotonic_Heap_heap;
typedef void *FStar_Monotonic_Heap_aref;
typedef void *FStar_Monotonic_HyperHeap_rid;
typedef void *FStar_Monotonic_HyperStack_mem;
typedef void *FStar_Char_char_;
typedef const char *Prims_string;
inline  __attribute__((always_inline)) static void private_memcpy(void *dest, const void *source, uint32_t size)
{
  uint8_t *dst = dest;
  const uint8_t *src = source;
  for (uint32_t i = 0; i < size; ++ i)
  {
    dst[i] = src[i];
  }

}

inline  __attribute__((always_inline)) static uint32_t load32(uint8_t *b)
{
  uint32_t x;
  private_memcpy(& x, b, 4);
  return x;
}

inline  __attribute__((always_inline)) static void store32(uint8_t *b, uint32_t i)
{
  private_memcpy(b, & i, 4);
}

inline  __attribute__((always_inline)) static void store64(uint8_t *b, uint64_t i)
{
  private_memcpy(b, & i, 8);
}

typedef int32_t Prims_pos;
typedef int32_t Prims_nat;
typedef int32_t Prims_nonzero;
typedef int32_t Prims_int;
typedef int32_t krml_checked_int_t;
typedef uint8_t Hacl_Hash_Lib_Create_uint8_t;
typedef uint32_t Hacl_Hash_Lib_Create_uint32_t;
typedef uint64_t Hacl_Hash_Lib_Create_uint64_t;
typedef uint8_t Hacl_Hash_Lib_Create_uint8_ht;
typedef uint32_t Hacl_Hash_Lib_Create_uint32_ht;
typedef uint64_t Hacl_Hash_Lib_Create_uint64_ht;
typedef uint8_t *Hacl_Hash_Lib_Create_uint8_p;
typedef uint32_t *Hacl_Hash_Lib_Create_uint32_p;
typedef uint64_t *Hacl_Hash_Lib_Create_uint64_p;
typedef uint8_t *Hacl_Hash_Lib_LoadStore_uint8_p;
typedef uint8_t Hacl_Impl_SHA2_256_uint8_t;
typedef uint32_t Hacl_Impl_SHA2_256_uint32_t;
typedef uint64_t Hacl_Impl_SHA2_256_uint64_t;
typedef uint8_t Hacl_Impl_SHA2_256_uint8_ht;
typedef uint32_t Hacl_Impl_SHA2_256_uint32_ht;
typedef uint64_t Hacl_Impl_SHA2_256_uint64_ht;
typedef uint32_t *Hacl_Impl_SHA2_256_uint32_p;
typedef uint8_t *Hacl_Impl_SHA2_256_uint8_p;
typedef uint8_t Hacl_Impl_HMAC_SHA2_256_uint8_t;
typedef uint32_t Hacl_Impl_HMAC_SHA2_256_uint32_t;
typedef uint64_t Hacl_Impl_HMAC_SHA2_256_uint64_t;
typedef uint8_t Hacl_Impl_HMAC_SHA2_256_uint8_ht;
typedef uint32_t Hacl_Impl_HMAC_SHA2_256_uint32_ht;
typedef uint64_t Hacl_Impl_HMAC_SHA2_256_uint64_ht;
typedef uint32_t *Hacl_Impl_HMAC_SHA2_256_uint32_p;
typedef uint8_t *Hacl_Impl_HMAC_SHA2_256_uint8_p;
typedef uint8_t uint8_ht;
typedef uint32_t uint32_t;
typedef uint8_t *uint8_p;
 __attribute__((section(".ipe_func"))) static void Hacl_Hash_Lib_LoadStore_uint32s_from_be_bytes(uint32_t *output, uint8_t *input, uint32_t len)
{
  for (uint32_t i = (uint32_t) 0U; i < len; i = i + ((uint32_t) 1U))
  {
    uint8_t *x0 = input + (((uint32_t) 4U) * i);
    uint32_t inputi =     {
      uint32_t _temp = load32(x0);
      ((((_temp >> 24) & 0x000000FF) | ((_temp >> 8) & 0x0000FF00)) | ((_temp << 8) & 0x00FF0000)) | ((_temp << 24) & 0xFF000000);
    }
;
    output[i] = inputi;
  }

}

 __attribute__((section(".ipe_func"))) static void Hacl_Hash_Lib_LoadStore_uint32s_to_be_bytes(uint8_t *output, uint32_t *input, uint32_t len)
{
  for (uint32_t i = (uint32_t) 0U; i < len; i = i + ((uint32_t) 1U))
  {
    uint32_t hd1 = input[i];
    uint8_t *x0 = output + (((uint32_t) 4U) * i);
    store32(x0,     {
      uint32_t _temp = hd1;
      ((((_temp >> 24) & 0x000000FF) | ((_temp >> 8) & 0x0000FF00)) | ((_temp << 8) & 0x00FF0000)) | ((_temp << 24) & 0xFF000000);
    }
);
  }

}

 __attribute__((section(".ipe_func"))) static void Hacl_Impl_SHA2_256_init(uint32_t *state)
{
  uint32_t *k1 = state;
  uint32_t *h_01 = state + ((uint32_t) 128U);
  uint32_t *p10 = k1;
  uint32_t *p20 = k1 + ((uint32_t) 16U);
  uint32_t *p3 = k1 + ((uint32_t) 32U);
  uint32_t *p4 = k1 + ((uint32_t) 48U);
  uint32_t *p11 = p10;
  uint32_t *p21 = p10 + ((uint32_t) 8U);
  uint32_t *p12 = p11;
  uint32_t *p22 = p11 + ((uint32_t) 4U);
  p12[0U] = (uint32_t) 0x428a2f98U;
  p12[1U] = (uint32_t) 0x71374491U;
  p12[2U] = (uint32_t) 0xb5c0fbcfU;
  p12[3U] = (uint32_t) 0xe9b5dba5U;
  p22[0U] = (uint32_t) 0x3956c25bU;
  p22[1U] = (uint32_t) 0x59f111f1U;
  p22[2U] = (uint32_t) 0x923f82a4U;
  p22[3U] = (uint32_t) 0xab1c5ed5U;
  uint32_t *p13 = p21;
  uint32_t *p23 = p21 + ((uint32_t) 4U);
  p13[0U] = (uint32_t) 0xd807aa98U;
  p13[1U] = (uint32_t) 0x12835b01U;
  p13[2U] = (uint32_t) 0x243185beU;
  p13[3U] = (uint32_t) 0x550c7dc3U;
  p23[0U] = (uint32_t) 0x72be5d74U;
  p23[1U] = (uint32_t) 0x80deb1feU;
  p23[2U] = (uint32_t) 0x9bdc06a7U;
  p23[3U] = (uint32_t) 0xc19bf174U;
  uint32_t *p14 = p20;
  uint32_t *p24 = p20 + ((uint32_t) 8U);
  uint32_t *p15 = p14;
  uint32_t *p25 = p14 + ((uint32_t) 4U);
  p15[0U] = (uint32_t) 0xe49b69c1U;
  p15[1U] = (uint32_t) 0xefbe4786U;
  p15[2U] = (uint32_t) 0x0fc19dc6U;
  p15[3U] = (uint32_t) 0x240ca1ccU;
  p25[0U] = (uint32_t) 0x2de92c6fU;
  p25[1U] = (uint32_t) 0x4a7484aaU;
  p25[2U] = (uint32_t) 0x5cb0a9dcU;
  p25[3U] = (uint32_t) 0x76f988daU;
  uint32_t *p16 = p24;
  uint32_t *p26 = p24 + ((uint32_t) 4U);
  p16[0U] = (uint32_t) 0x983e5152U;
  p16[1U] = (uint32_t) 0xa831c66dU;
  p16[2U] = (uint32_t) 0xb00327c8U;
  p16[3U] = (uint32_t) 0xbf597fc7U;
  p26[0U] = (uint32_t) 0xc6e00bf3U;
  p26[1U] = (uint32_t) 0xd5a79147U;
  p26[2U] = (uint32_t) 0x06ca6351U;
  p26[3U] = (uint32_t) 0x14292967U;
  uint32_t *p17 = p3;
  uint32_t *p27 = p3 + ((uint32_t) 8U);
  uint32_t *p18 = p17;
  uint32_t *p28 = p17 + ((uint32_t) 4U);
  p18[0U] = (uint32_t) 0x27b70a85U;
  p18[1U] = (uint32_t) 0x2e1b2138U;
  p18[2U] = (uint32_t) 0x4d2c6dfcU;
  p18[3U] = (uint32_t) 0x53380d13U;
  p28[0U] = (uint32_t) 0x650a7354U;
  p28[1U] = (uint32_t) 0x766a0abbU;
  p28[2U] = (uint32_t) 0x81c2c92eU;
  p28[3U] = (uint32_t) 0x92722c85U;
  uint32_t *p19 = p27;
  uint32_t *p29 = p27 + ((uint32_t) 4U);
  p19[0U] = (uint32_t) 0xa2bfe8a1U;
  p19[1U] = (uint32_t) 0xa81a664bU;
  p19[2U] = (uint32_t) 0xc24b8b70U;
  p19[3U] = (uint32_t) 0xc76c51a3U;
  p29[0U] = (uint32_t) 0xd192e819U;
  p29[1U] = (uint32_t) 0xd6990624U;
  p29[2U] = (uint32_t) 0xf40e3585U;
  p29[3U] = (uint32_t) 0x106aa070U;
  uint32_t *p110 = p4;
  uint32_t *p210 = p4 + ((uint32_t) 8U);
  uint32_t *p1 = p110;
  uint32_t *p211 = p110 + ((uint32_t) 4U);
  p1[0U] = (uint32_t) 0x19a4c116U;
  p1[1U] = (uint32_t) 0x1e376c08U;
  p1[2U] = (uint32_t) 0x2748774cU;
  p1[3U] = (uint32_t) 0x34b0bcb5U;
  p211[0U] = (uint32_t) 0x391c0cb3U;
  p211[1U] = (uint32_t) 0x4ed8aa4aU;
  p211[2U] = (uint32_t) 0x5b9cca4fU;
  p211[3U] = (uint32_t) 0x682e6ff3U;
  uint32_t *p111 = p210;
  uint32_t *p212 = p210 + ((uint32_t) 4U);
  p111[0U] = (uint32_t) 0x748f82eeU;
  p111[1U] = (uint32_t) 0x78a5636fU;
  p111[2U] = (uint32_t) 0x84c87814U;
  p111[3U] = (uint32_t) 0x8cc70208U;
  p212[0U] = (uint32_t) 0x90befffaU;
  p212[1U] = (uint32_t) 0xa4506cebU;
  p212[2U] = (uint32_t) 0xbef9a3f7U;
  p212[3U] = (uint32_t) 0xc67178f2U;
  uint32_t *p112 = h_01;
  uint32_t *p2 = h_01 + ((uint32_t) 4U);
  p112[0U] = (uint32_t) 0x6a09e667U;
  p112[1U] = (uint32_t) 0xbb67ae85U;
  p112[2U] = (uint32_t) 0x3c6ef372U;
  p112[3U] = (uint32_t) 0xa54ff53aU;
  p2[0U] = (uint32_t) 0x510e527fU;
  p2[1U] = (uint32_t) 0x9b05688cU;
  p2[2U] = (uint32_t) 0x1f83d9abU;
  p2[3U] = (uint32_t) 0x5be0cd19U;
}

 __attribute__((section(".ipe_func"))) static void Hacl_Impl_SHA2_256_update(uint32_t *state, uint8_t *data)
{
  uint32_t data_w[16U] = {0U};
  Hacl_Hash_Lib_LoadStore_uint32s_from_be_bytes(data_w, data, (uint32_t) 16U);
  uint32_t *hash_w = state + ((uint32_t) 128U);
  uint32_t *ws_w = state + ((uint32_t) 64U);
  uint32_t *k_w = state;
  uint32_t *counter_w = state + ((uint32_t) 136U);
  for (uint32_t i = (uint32_t) 0U; i < ((uint32_t) 16U); i = i + ((uint32_t) 1U))
  {
    uint32_t b = data_w[i];
    ws_w[i] = b;
  }

  for (uint32_t i = (uint32_t) 16U; i < ((uint32_t) 64U); i = i + ((uint32_t) 1U))
  {
    uint32_t t16 = ws_w[i - ((uint32_t) 16U)];
    uint32_t t15 = ws_w[i - ((uint32_t) 15U)];
    uint32_t t7 = ws_w[i - ((uint32_t) 7U)];
    uint32_t t2 = ws_w[i - ((uint32_t) 2U)];
    ws_w[i] = (((((t2 >> ((uint32_t) 17U)) | (t2 << (((uint32_t) 32U) - ((uint32_t) 17U)))) ^ (((t2 >> ((uint32_t) 19U)) | (t2 << (((uint32_t) 32U) - ((uint32_t) 19U)))) ^ (t2 >> ((uint32_t) 10U)))) + t7) + (((t15 >> ((uint32_t) 7U)) | (t15 << (((uint32_t) 32U) - ((uint32_t) 7U)))) ^ (((t15 >> ((uint32_t) 18U)) | (t15 << (((uint32_t) 32U) - ((uint32_t) 18U)))) ^ (t15 >> ((uint32_t) 3U))))) + t16;
  }

  uint32_t hash_0[8U] = {0U};
  private_memcpy(hash_0, hash_w, ((uint32_t) 8U) * (sizeof(hash_w[0U])));
  for (uint32_t i = (uint32_t) 0U; i < ((uint32_t) 64U); i = i + ((uint32_t) 1U))
  {
    uint32_t a = hash_0[0U];
    uint32_t b = hash_0[1U];
    uint32_t c = hash_0[2U];
    uint32_t d = hash_0[3U];
    uint32_t e = hash_0[4U];
    uint32_t f1 = hash_0[5U];
    uint32_t g = hash_0[6U];
    uint32_t h = hash_0[7U];
    uint32_t kt = k_w[i];
    uint32_t wst = ws_w[i];
    uint32_t t1 = (((h + (((e >> ((uint32_t) 6U)) | (e << (((uint32_t) 32U) - ((uint32_t) 6U)))) ^ (((e >> ((uint32_t) 11U)) | (e << (((uint32_t) 32U) - ((uint32_t) 11U)))) ^ ((e >> ((uint32_t) 25U)) | (e << (((uint32_t) 32U) - ((uint32_t) 25U))))))) + ((e & f1) ^ ((~ e) & g))) + kt) + wst;
    uint32_t t2 = (((a >> ((uint32_t) 2U)) | (a << (((uint32_t) 32U) - ((uint32_t) 2U)))) ^ (((a >> ((uint32_t) 13U)) | (a << (((uint32_t) 32U) - ((uint32_t) 13U)))) ^ ((a >> ((uint32_t) 22U)) | (a << (((uint32_t) 32U) - ((uint32_t) 22U)))))) + ((a & b) ^ ((a & c) ^ (b & c)));
    uint32_t x1 = t1 + t2;
    uint32_t x5 = d + t1;
    uint32_t *p1 = hash_0;
    uint32_t *p2 = hash_0 + ((uint32_t) 4U);
    p1[0U] = x1;
    p1[1U] = a;
    p1[2U] = b;
    p1[3U] = c;
    p2[0U] = x5;
    p2[1U] = e;
    p2[2U] = f1;
    p2[3U] = g;
  }

  for (uint32_t i = (uint32_t) 0U; i < ((uint32_t) 8U); i = i + ((uint32_t) 1U))
  {
    uint32_t xi = hash_w[i];
    uint32_t yi = hash_0[i];
    hash_w[i] = xi + yi;
  }

  uint32_t c0 = counter_w[0U];
  uint32_t one1 = (uint32_t) 1U;
  counter_w[0U] = c0 + one1;
}

 __attribute__((section(".ipe_func"))) static void Hacl_Impl_SHA2_256_update_multi(uint32_t *state, uint8_t *data, uint32_t n1)
{
  for (uint32_t i = (uint32_t) 0U; i < n1; i = i + ((uint32_t) 1U))
  {
    uint8_t *b = data + (i * ((uint32_t) 64U));
    Hacl_Impl_SHA2_256_update(state, b);
  }

}

 __attribute__((section(".ipe_func"))) static void Hacl_Impl_SHA2_256_update_last(uint32_t *state, uint8_t *data, uint32_t len)
{
  uint8_t blocks[128U] = {0U};
  uint32_t nb;
  if (len < ((uint32_t) 56U))
    nb = (uint32_t) 1U;
  else
    nb = (uint32_t) 2U;
  uint8_t *final_blocks;
  if (len < ((uint32_t) 56U))
    final_blocks = blocks + ((uint32_t) 64U);
  else
    final_blocks = blocks;
  private_memcpy(final_blocks, data, len * (sizeof(data[0U])));
  uint32_t n1 = state[136U];
  uint8_t *padding = final_blocks + len;
  uint32_t pad0len = (((uint32_t) 64U) - (((len + ((uint32_t) 8U)) + ((uint32_t) 1U)) % ((uint32_t) 64U))) % ((uint32_t) 64U);
  uint8_t *buf1 = padding;
  uint8_t *buf2 = (padding + ((uint32_t) 1U)) + pad0len;
  uint64_t encodedlen = ((((uint64_t) n1) * ((uint64_t) ((uint32_t) 64U))) + ((uint64_t) len)) * ((uint64_t) ((uint32_t) 8U));
  buf1[0U] = (uint8_t) 0x80U;
  store64(buf2,   {
    uint64_t __temp = encodedlen;
    uint32_t __low =     {
      uint32_t _temp = (uint32_t) __temp;
      ((((_temp >> 24) & 0x000000FF) | ((_temp >> 8) & 0x0000FF00)) | ((_temp << 8) & 0x00FF0000)) | ((_temp << 24) & 0xFF000000);
    }
;
    uint32_t __high =     {
      uint32_t _temp = (uint32_t) (__temp >> 32);
      ((((_temp >> 24) & 0x000000FF) | ((_temp >> 8) & 0x0000FF00)) | ((_temp << 8) & 0x00FF0000)) | ((_temp << 24) & 0xFF000000);
    }
;
    (((uint64_t) __low) << 32) | __high;
  }
);
  Hacl_Impl_SHA2_256_update_multi(state, final_blocks, nb);
}

 __attribute__((section(".ipe_func"))) static void Hacl_Impl_SHA2_256_finish(uint32_t *state, uint8_t *hash1)
{
  uint32_t *hash_w = state + ((uint32_t) 128U);
  Hacl_Hash_Lib_LoadStore_uint32s_to_be_bytes(hash1, hash_w, (uint32_t) 8U);
}

 __attribute__((section(".ipe_func"))) static void Hacl_Impl_SHA2_256_hash(uint8_t *hash1, uint8_t *input, uint32_t len)
{
  uint32_t state[137U] = {0U};
  uint32_t n1 = len / ((uint32_t) 64U);
  uint32_t r = len % ((uint32_t) 64U);
  uint8_t *input_blocks = input;
  uint8_t *input_last = input + (n1 * ((uint32_t) 64U));
  Hacl_Impl_SHA2_256_init(state);
  Hacl_Impl_SHA2_256_update_multi(state, input_blocks, n1);
  Hacl_Impl_SHA2_256_update_last(state, input_last, r);
  Hacl_Impl_SHA2_256_finish(state, hash1);
}

 __attribute__((section(".ipe_func"))) static void Hacl_Impl_HMAC_SHA2_256_xor_bytes_inplace(uint8_t *a, uint8_t *b, uint32_t len)
{
  for (uint32_t i = (uint32_t) 0U; i < len; i = i + ((uint32_t) 1U))
  {
    uint8_t xi = a[i];
    uint8_t yi = b[i];
    a[i] = xi ^ yi;
  }

}

 __attribute__((section(".ipe_func"))) static void Hacl_Impl_HMAC_SHA2_256_hmac_core(uint8_t *mac, uint8_t *key, uint8_t *data, uint32_t len)
{
  uint8_t ipad[64U];
  for (uint32_t _i = 0U; _i < ((uint32_t) 64U); ++ _i)
    ipad[_i] = (uint8_t) 0x36U;

  uint8_t opad[64U];
  for (uint32_t _i = 0U; _i < ((uint32_t) 64U); ++ _i)
    opad[_i] = (uint8_t) 0x5cU;

  Hacl_Impl_HMAC_SHA2_256_xor_bytes_inplace(ipad, key, (uint32_t) 64U);
  uint32_t state0[137U] = {0U};
  uint32_t n0 = len / ((uint32_t) 64U);
  uint32_t r0 = len % ((uint32_t) 64U);
  uint8_t *blocks0 = data;
  uint8_t *last0 = data + (n0 * ((uint32_t) 64U));
  Hacl_Impl_SHA2_256_init(state0);
  Hacl_Impl_SHA2_256_update(state0, ipad);
  Hacl_Impl_SHA2_256_update_multi(state0, blocks0, n0);
  Hacl_Impl_SHA2_256_update_last(state0, last0, r0);
  uint8_t *hash0 = ipad;
  Hacl_Impl_SHA2_256_finish(state0, hash0);
  uint8_t *s4 = ipad;
  Hacl_Impl_HMAC_SHA2_256_xor_bytes_inplace(opad, key, (uint32_t) 64U);
  uint32_t state1[137U] = {0U};
  Hacl_Impl_SHA2_256_init(state1);
  Hacl_Impl_SHA2_256_update(state1, opad);
  Hacl_Impl_SHA2_256_update_last(state1, s4, (uint32_t) 32U);
  Hacl_Impl_SHA2_256_finish(state1, mac);
}

 __attribute__((section(".ipe_func"))) static void Hacl_Impl_HMAC_SHA2_256_hmac(uint8_t *mac, uint8_t *key, uint32_t keylen, uint8_t *data, uint32_t datalen)
{
  uint8_t nkey[64U];
  for (uint32_t _i = 0U; _i < ((uint32_t) 64U); ++ _i)
    nkey[_i] = (uint8_t) 0x00U;

  if (keylen <= ((uint32_t) 64U))
    private_memcpy(nkey, key, keylen * (sizeof(key[0U])));
  else
  {
    uint8_t *nkey0 = nkey;
    Hacl_Impl_SHA2_256_hash(nkey0, key, keylen);
  }
  Hacl_Impl_HMAC_SHA2_256_hmac_core(mac, nkey, data, datalen);
}

 __attribute__((section(".ipe_func"))) void hmac_core(uint8_t *mac, uint8_t *key, uint8_t *data, uint32_t len)
{
  Hacl_Impl_HMAC_SHA2_256_hmac_core(mac, key, data, len);
}

 __attribute__((section(".ipe_func"))) void hmac(uint8_t *mac, uint8_t *key, uint32_t keylen, uint8_t *data, uint32_t datalen)
{
  Hacl_Impl_HMAC_SHA2_256_hmac(mac, key, keylen, data, datalen);
}

 __attribute__((section(".ipe_const"))) uint8_t persistent_key[65] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
 __attribute__((section(".ipe_entry"))) int attest_internal(void)
{
  uint8_t key[64] = {0};
  for (int i = 0; i < 64; ++ i)
  {
    key[i] = persistent_key[i];
  }

  hmac((uint8_t *) key, (uint8_t *) key, (uint32_t) 64, (uint8_t *) mac_region, (uint32_t) 32);
  hmac((uint8_t *) mac_region, (uint8_t *) key, (uint32_t) 32, (uint8_t *) 0x1000, (uint32_t) 0x0800);
  return signal_done_stub(3);
}

