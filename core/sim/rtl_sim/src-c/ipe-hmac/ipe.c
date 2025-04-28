#include "mock.h"
#include "../framework/libipe/ipe_support.h"
#include "output/generated_ipe_header.h"

DECLARE_IPE_STRUCT;

int signal_done(int);
extern uint8_t mac_region[];

/******************************************************************************/
/* Implementing C.fst                                                         */
/******************************************************************************/

/* Uppercase issue; we have to define lowercase versions of the C macros (as we
 * have no way to refer to an uppercase *variable* in F*). */
extern int exit_success;
extern int exit_failure;

/* This one allows the user to write C.EXIT_SUCCESS. */
typedef int exit_code;

void print_string(const char *s);
void print_bytes(uint8_t *b, uint32_t len);

/* The universal null pointer defined in C.Nullity.fst */
#define C_Nullity_null(X) 0

/* If some globals need to be initialized before the main, then kremlin will
 * generate and try to link last a function with this type: */
void kremlinit_globals(void);

/******************************************************************************/
/* Implementation of machine integers (possibly of 128-bit integers)          */
/******************************************************************************/

/* Integer types */
typedef uint64_t FStar_UInt64_t, FStar_UInt64_t_;
typedef int64_t FStar_Int64_t, FStar_Int64_t_;
typedef uint32_t FStar_UInt32_t, FStar_UInt32_t_;
typedef int32_t FStar_Int32_t, FStar_Int32_t_;
typedef uint16_t FStar_UInt16_t, FStar_UInt16_t_;
typedef int16_t FStar_Int16_t, FStar_Int16_t_;
typedef uint8_t FStar_UInt8_t, FStar_UInt8_t_;
typedef int8_t FStar_Int8_t, FStar_Int8_t_;


// end of kremlib_base

// start of kremlib

/* For tests only: we might need this function to be forward-declared, because
 * the dependency on WasmSupport appears very late, after SimplifyWasm, and
 * sadly, after the topological order has been done. */
void WasmSupport_check_buffer_size(uint32_t s);

/******************************************************************************/
/* Stubs to ease compilation of non-Low* code                                 */
/******************************************************************************/

/* Some types that KreMLin has no special knowledge of; many of them appear in
 * signatures of ghost functions, meaning that it suffices to give them (any)
 * definition. */
typedef void *FStar_Seq_Base_seq, *Prims_prop, *FStar_HyperStack_mem,
    *FStar_Set_set, *Prims_st_pre_h, *FStar_Heap_heap, *Prims_all_pre_h,
    *FStar_TSet_set, *Prims_list, *FStar_Map_t, *FStar_UInt63_t_,
    *FStar_Int63_t_, *FStar_UInt63_t, *FStar_Int63_t, *FStar_UInt_uint_t,
    *FStar_Int_int_t, *FStar_HyperStack_stackref, *FStar_Bytes_bytes,
    *FStar_HyperHeap_rid, *FStar_Heap_aref, *FStar_Monotonic_Heap_heap,
    *FStar_Monotonic_Heap_aref, *FStar_Monotonic_HyperHeap_rid,
    *FStar_Monotonic_HyperStack_mem, *FStar_Char_char_;

typedef const char *Prims_string;



#define FStar_Buffer_eqb(b1, b2, n)                                            \
  (memcmp((b1), (b2), (n) * sizeof((b1)[0])) == 0)

/* Stubs to make ST happy. Important note: you must generate a use of the macro
 * argument, otherwise, you may have FStar_ST_recall(f) as the only use of f;
 * KreMLin will think that this is a valid use, but then the C compiler, after
 * macro expansion, will error out. */
#define FStar_HyperHeap_root 0
#define FStar_Pervasives_Native_fst(x) (x).fst
#define FStar_Pervasives_Native_snd(x) (x).snd
#define FStar_Seq_Base_createEmpty(x) 0
#define FStar_Seq_Base_create(len, init) 0
#define FStar_Seq_Base_upd(s, i, e) 0
#define FStar_Seq_Base_eq(l1, l2) 0
#define FStar_Seq_Base_length(l1) 0
#define FStar_Seq_Base_append(x, y) 0
#define FStar_Seq_Base_slice(x, y, z) 0
#define FStar_Seq_Properties_snoc(x, y) 0
#define FStar_Seq_Properties_cons(x, y) 0
#define FStar_Seq_Base_index(x, y) 0
#define FStar_HyperStack_is_eternal_color(x) 0
#define FStar_Monotonic_HyperHeap_root 0
#define FStar_Buffer_to_seq_full(x) 0
#define FStar_Buffer_recall(x)
//#define FStar_HyperStack_ST_op_Colon_Equals(x, v) KRML_EXIT
#define FStar_HyperStack_ST_op_Bang(x) 0
#define FStar_HyperStack_ST_salloc(x) 0
#define FStar_HyperStack_ST_ralloc(x, y) 0
#define FStar_HyperStack_ST_new_region(x) (0)
#define FStar_Monotonic_RRef_m_alloc(x)                                        \
  { 0 }

#define FStar_HyperStack_ST_recall(x)                                          \
  do {                                                                         \
    (void)(x);                                                                 \
  } while (0)

#define FStar_HyperStack_ST_recall_region(x)                                   \
  do {                                                                         \
    (void)(x);                                                                 \
  } while (0)

#define FStar_Monotonic_RRef_m_recall(x1, x2)                                  \
  do {                                                                         \
    (void)(x1);                                                                \
    (void)(x2);                                                                \
  } while (0)

#define FStar_Monotonic_RRef_m_write(x1, x2, x3, x4, x5)                       \
  do {                                                                         \
    (void)(x1);                                                                \
    (void)(x2);                                                                \
    (void)(x3);                                                                \
    (void)(x4);                                                                \
    (void)(x5);                                                                \
  } while (0)

/******************************************************************************/
/* Endian-ness macros that can only be implemented in C                       */
/******************************************************************************/

#  define htole32(x) (x)
#  define le32toh(x) (x)
#  define htobe32(x)                                                           \
    (({                                                           \
      uint32_t _temp = (x);                                                    \
      ((_temp >> 24) & 0x000000FF) | ((_temp >> 8) & 0x0000FF00) |             \
          ((_temp << 8) & 0x00FF0000) | ((_temp << 24) & 0xFF000000);          \
    }))
#  define be32toh(x) (htobe32((x)))

#  define htole64(x) (x)
#  define le64toh(x) (x)
#  define htobe64(x)                                                           \
    (({                                                           \
      uint64_t __temp = (x);                                                   \
      uint32_t __low = htobe32((uint32_t)__temp);                              \
      uint32_t __high = htobe32((uint32_t)(__temp >> 32));                     \
      (((uint64_t)__low) << 32) | __high;                                      \
    }))
#  define be64toh(x) (htobe64((x)))

always_inline void private_memcpy(void *dest, const void *source, uint32_t size) {
    uint8_t *dst = dest;
    const uint8_t *src = source;
    for (uint32_t i = 0; i < size; ++i) {
        dst[i] = src[i];
    }
}

/* Loads and stores. These avoid undefined behavior due to unaligned memory
 * accesses, via memcpy. */

always_inline uint32_t load32(uint8_t *b) {
  uint32_t x;
  private_memcpy(&x, b, 4);
  return x;
}

always_inline void store32(uint8_t *b, uint32_t i) { private_memcpy(b, &i, 4); }

always_inline void store64(uint8_t *b, uint64_t i) { private_memcpy(b, &i, 8); }

#define load16_le(b) (le16toh(load16(b)))
#define store16_le(b, i) (store16(b, htole16(i)))
#define load16_be(b) (be16toh(load16(b)))
#define store16_be(b, i) (store16(b, htobe16(i)))

#define load32_le(b) (le32toh(load32(b)))
#define store32_le(b, i) (store32(b, htole32(i)))
#define load32_be(b) (be32toh(load32(b)))
#define store32_be(b, i) (store32(b, htobe32(i)))

#define load64_le(b) (le64toh(load64(b)))
#define store64_le(b, i) (store64(b, htole64(i)))
#define load64_be(b) (be64toh(load64(b)))
#define store64_be(b, i) (store64(b, htobe64(i)))

/******************************************************************************/
/* Checked integers to ease the compilation of non-Low* code                  */
/******************************************************************************/

typedef int32_t Prims_pos, Prims_nat, Prims_nonzero, Prims_int,
    krml_checked_int_t;

// end of kremlib

// start of sha2


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

// sha2.c

static void IPE_FUNC
Hacl_Hash_Lib_LoadStore_uint32s_from_be_bytes(uint32_t *output, uint8_t *input, uint32_t len)
{
  for (uint32_t i = (uint32_t)0U; i < len; i = i + (uint32_t)1U)
  {
    uint8_t *x0 = input + (uint32_t)4U * i;
    uint32_t inputi = load32_be(x0);
    output[i] = inputi;
  }
}

static void IPE_FUNC
Hacl_Hash_Lib_LoadStore_uint32s_to_be_bytes(uint8_t *output, uint32_t *input, uint32_t len)
{
  for (uint32_t i = (uint32_t)0U; i < len; i = i + (uint32_t)1U)
  {
    uint32_t hd1 = input[i];
    uint8_t *x0 = output + (uint32_t)4U * i;
    store32_be(x0, hd1);
  }
}

static void IPE_FUNC Hacl_Impl_SHA2_256_init(uint32_t *state)
{
  uint32_t *k1 = state;
  uint32_t *h_01 = state + (uint32_t)128U;
  uint32_t *p10 = k1;
  uint32_t *p20 = k1 + (uint32_t)16U;
  uint32_t *p3 = k1 + (uint32_t)32U;
  uint32_t *p4 = k1 + (uint32_t)48U;
  uint32_t *p11 = p10;
  uint32_t *p21 = p10 + (uint32_t)8U;
  uint32_t *p12 = p11;
  uint32_t *p22 = p11 + (uint32_t)4U;
  p12[0U] = (uint32_t)0x428a2f98U;
  p12[1U] = (uint32_t)0x71374491U;
  p12[2U] = (uint32_t)0xb5c0fbcfU;
  p12[3U] = (uint32_t)0xe9b5dba5U;
  p22[0U] = (uint32_t)0x3956c25bU;
  p22[1U] = (uint32_t)0x59f111f1U;
  p22[2U] = (uint32_t)0x923f82a4U;
  p22[3U] = (uint32_t)0xab1c5ed5U;
  uint32_t *p13 = p21;
  uint32_t *p23 = p21 + (uint32_t)4U;
  p13[0U] = (uint32_t)0xd807aa98U;
  p13[1U] = (uint32_t)0x12835b01U;
  p13[2U] = (uint32_t)0x243185beU;
  p13[3U] = (uint32_t)0x550c7dc3U;
  p23[0U] = (uint32_t)0x72be5d74U;
  p23[1U] = (uint32_t)0x80deb1feU;
  p23[2U] = (uint32_t)0x9bdc06a7U;
  p23[3U] = (uint32_t)0xc19bf174U;
  uint32_t *p14 = p20;
  uint32_t *p24 = p20 + (uint32_t)8U;
  uint32_t *p15 = p14;
  uint32_t *p25 = p14 + (uint32_t)4U;
  p15[0U] = (uint32_t)0xe49b69c1U;
  p15[1U] = (uint32_t)0xefbe4786U;
  p15[2U] = (uint32_t)0x0fc19dc6U;
  p15[3U] = (uint32_t)0x240ca1ccU;
  p25[0U] = (uint32_t)0x2de92c6fU;
  p25[1U] = (uint32_t)0x4a7484aaU;
  p25[2U] = (uint32_t)0x5cb0a9dcU;
  p25[3U] = (uint32_t)0x76f988daU;
  uint32_t *p16 = p24;
  uint32_t *p26 = p24 + (uint32_t)4U;
  p16[0U] = (uint32_t)0x983e5152U;
  p16[1U] = (uint32_t)0xa831c66dU;
  p16[2U] = (uint32_t)0xb00327c8U;
  p16[3U] = (uint32_t)0xbf597fc7U;
  p26[0U] = (uint32_t)0xc6e00bf3U;
  p26[1U] = (uint32_t)0xd5a79147U;
  p26[2U] = (uint32_t)0x06ca6351U;
  p26[3U] = (uint32_t)0x14292967U;
  uint32_t *p17 = p3;
  uint32_t *p27 = p3 + (uint32_t)8U;
  uint32_t *p18 = p17;
  uint32_t *p28 = p17 + (uint32_t)4U;
  p18[0U] = (uint32_t)0x27b70a85U;
  p18[1U] = (uint32_t)0x2e1b2138U;
  p18[2U] = (uint32_t)0x4d2c6dfcU;
  p18[3U] = (uint32_t)0x53380d13U;
  p28[0U] = (uint32_t)0x650a7354U;
  p28[1U] = (uint32_t)0x766a0abbU;
  p28[2U] = (uint32_t)0x81c2c92eU;
  p28[3U] = (uint32_t)0x92722c85U;
  uint32_t *p19 = p27;
  uint32_t *p29 = p27 + (uint32_t)4U;
  p19[0U] = (uint32_t)0xa2bfe8a1U;
  p19[1U] = (uint32_t)0xa81a664bU;
  p19[2U] = (uint32_t)0xc24b8b70U;
  p19[3U] = (uint32_t)0xc76c51a3U;
  p29[0U] = (uint32_t)0xd192e819U;
  p29[1U] = (uint32_t)0xd6990624U;
  p29[2U] = (uint32_t)0xf40e3585U;
  p29[3U] = (uint32_t)0x106aa070U;
  uint32_t *p110 = p4;
  uint32_t *p210 = p4 + (uint32_t)8U;
  uint32_t *p1 = p110;
  uint32_t *p211 = p110 + (uint32_t)4U;
  p1[0U] = (uint32_t)0x19a4c116U;
  p1[1U] = (uint32_t)0x1e376c08U;
  p1[2U] = (uint32_t)0x2748774cU;
  p1[3U] = (uint32_t)0x34b0bcb5U;
  p211[0U] = (uint32_t)0x391c0cb3U;
  p211[1U] = (uint32_t)0x4ed8aa4aU;
  p211[2U] = (uint32_t)0x5b9cca4fU;
  p211[3U] = (uint32_t)0x682e6ff3U;
  uint32_t *p111 = p210;
  uint32_t *p212 = p210 + (uint32_t)4U;
  p111[0U] = (uint32_t)0x748f82eeU;
  p111[1U] = (uint32_t)0x78a5636fU;
  p111[2U] = (uint32_t)0x84c87814U;
  p111[3U] = (uint32_t)0x8cc70208U;
  p212[0U] = (uint32_t)0x90befffaU;
  p212[1U] = (uint32_t)0xa4506cebU;
  p212[2U] = (uint32_t)0xbef9a3f7U;
  p212[3U] = (uint32_t)0xc67178f2U;
  uint32_t *p112 = h_01;
  uint32_t *p2 = h_01 + (uint32_t)4U;
  p112[0U] = (uint32_t)0x6a09e667U;
  p112[1U] = (uint32_t)0xbb67ae85U;
  p112[2U] = (uint32_t)0x3c6ef372U;
  p112[3U] = (uint32_t)0xa54ff53aU;
  p2[0U] = (uint32_t)0x510e527fU;
  p2[1U] = (uint32_t)0x9b05688cU;
  p2[2U] = (uint32_t)0x1f83d9abU;
  p2[3U] = (uint32_t)0x5be0cd19U;
}

static void IPE_FUNC Hacl_Impl_SHA2_256_update(uint32_t *state, uint8_t *data)
{
  uint32_t data_w[16U] = { 0U };
  Hacl_Hash_Lib_LoadStore_uint32s_from_be_bytes(data_w, data, (uint32_t)16U);
  uint32_t *hash_w = state + (uint32_t)128U;
  uint32_t *ws_w = state + (uint32_t)64U;
  uint32_t *k_w = state;
  uint32_t *counter_w = state + (uint32_t)136U;
  for (uint32_t i = (uint32_t)0U; i < (uint32_t)16U; i = i + (uint32_t)1U)
  {
    uint32_t b = data_w[i];
    ws_w[i] = b;
  }
  for (uint32_t i = (uint32_t)16U; i < (uint32_t)64U; i = i + (uint32_t)1U)
  {
    uint32_t t16 = ws_w[i - (uint32_t)16U];
    uint32_t t15 = ws_w[i - (uint32_t)15U];
    uint32_t t7 = ws_w[i - (uint32_t)7U];
    uint32_t t2 = ws_w[i - (uint32_t)2U];
    ws_w[i] =
      ((t2 >> (uint32_t)17U | t2 << ((uint32_t)32U - (uint32_t)17U))
      ^ ((t2 >> (uint32_t)19U | t2 << ((uint32_t)32U - (uint32_t)19U)) ^ t2 >> (uint32_t)10U))
      +
        t7
        +
          ((t15 >> (uint32_t)7U | t15 << ((uint32_t)32U - (uint32_t)7U))
          ^ ((t15 >> (uint32_t)18U | t15 << ((uint32_t)32U - (uint32_t)18U)) ^ t15 >> (uint32_t)3U))
          + t16;
  }
  uint32_t hash_0[8U] = { 0U };
  private_memcpy(hash_0, hash_w, (uint32_t)8U * sizeof hash_w[0U]);
  for (uint32_t i = (uint32_t)0U; i < (uint32_t)64U; i = i + (uint32_t)1U)
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
    uint32_t
    t1 =
      h
      +
        ((e >> (uint32_t)6U | e << ((uint32_t)32U - (uint32_t)6U))
        ^
          ((e >> (uint32_t)11U | e << ((uint32_t)32U - (uint32_t)11U))
          ^ (e >> (uint32_t)25U | e << ((uint32_t)32U - (uint32_t)25U))))
      + ((e & f1) ^ (~e & g))
      + kt
      + wst;
    uint32_t
    t2 =
      ((a >> (uint32_t)2U | a << ((uint32_t)32U - (uint32_t)2U))
      ^
        ((a >> (uint32_t)13U | a << ((uint32_t)32U - (uint32_t)13U))
        ^ (a >> (uint32_t)22U | a << ((uint32_t)32U - (uint32_t)22U))))
      + ((a & b) ^ ((a & c) ^ (b & c)));
    uint32_t x1 = t1 + t2;
    uint32_t x5 = d + t1;
    uint32_t *p1 = hash_0;
    uint32_t *p2 = hash_0 + (uint32_t)4U;
    p1[0U] = x1;
    p1[1U] = a;
    p1[2U] = b;
    p1[3U] = c;
    p2[0U] = x5;
    p2[1U] = e;
    p2[2U] = f1;
    p2[3U] = g;
  }
  for (uint32_t i = (uint32_t)0U; i < (uint32_t)8U; i = i + (uint32_t)1U)
  {
    uint32_t xi = hash_w[i];
    uint32_t yi = hash_0[i];
    hash_w[i] = xi + yi;
  }
  uint32_t c0 = counter_w[0U];
  uint32_t one1 = (uint32_t)1U;
  counter_w[0U] = c0 + one1;
}

static void IPE_FUNC Hacl_Impl_SHA2_256_update_multi(uint32_t *state, uint8_t *data, uint32_t n1)
{
  for (uint32_t i = (uint32_t)0U; i < n1; i = i + (uint32_t)1U)
  {
    uint8_t *b = data + i * (uint32_t)64U;
    Hacl_Impl_SHA2_256_update(state, b);
  }
}

static void IPE_FUNC Hacl_Impl_SHA2_256_update_last(uint32_t *state, uint8_t *data, uint32_t len)
{
  uint8_t blocks[128U] = { 0U };
  uint32_t nb;
  if (len < (uint32_t)56U)
    nb = (uint32_t)1U;
  else
    nb = (uint32_t)2U;
  uint8_t *final_blocks;
  if (len < (uint32_t)56U)
    final_blocks = blocks + (uint32_t)64U;
  else
    final_blocks = blocks;
  private_memcpy(final_blocks, data, len * sizeof data[0U]);
  uint32_t n1 = state[136U];
  uint8_t *padding = final_blocks + len;
  uint32_t
  pad0len = ((uint32_t)64U - (len + (uint32_t)8U + (uint32_t)1U) % (uint32_t)64U) % (uint32_t)64U;
  uint8_t *buf1 = padding;
  uint8_t *buf2 = padding + (uint32_t)1U + pad0len;
  uint64_t
  encodedlen = ((uint64_t)n1 * (uint64_t)(uint32_t)64U + (uint64_t)len) * (uint64_t)(uint32_t)8U;
  buf1[0U] = (uint8_t)0x80U;
  store64_be(buf2, encodedlen);
  Hacl_Impl_SHA2_256_update_multi(state, final_blocks, nb);
}

static void IPE_FUNC Hacl_Impl_SHA2_256_finish(uint32_t *state, uint8_t *hash1)
{
  uint32_t *hash_w = state + (uint32_t)128U;
  Hacl_Hash_Lib_LoadStore_uint32s_to_be_bytes(hash1, hash_w, (uint32_t)8U);
}

static void IPE_FUNC Hacl_Impl_SHA2_256_hash(uint8_t *hash1, uint8_t *input, uint32_t len)
{
  uint32_t state[137U] = { 0U };
  uint32_t n1 = len / (uint32_t)64U;
  uint32_t r = len % (uint32_t)64U;
  uint8_t *input_blocks = input;
  uint8_t *input_last = input + n1 * (uint32_t)64U;
  Hacl_Impl_SHA2_256_init(state);
  Hacl_Impl_SHA2_256_update_multi(state, input_blocks, n1);
  Hacl_Impl_SHA2_256_update_last(state, input_last, r);
  Hacl_Impl_SHA2_256_finish(state, hash1);
}

static void IPE_FUNC Hacl_Impl_HMAC_SHA2_256_xor_bytes_inplace(uint8_t *a, uint8_t *b, uint32_t len)
{
  for (uint32_t i = (uint32_t)0U; i < len; i = i + (uint32_t)1U)
  {
    uint8_t xi = a[i];
    uint8_t yi = b[i];
    a[i] = xi ^ yi;
  }
}

static void IPE_FUNC
Hacl_Impl_HMAC_SHA2_256_hmac_core(uint8_t *mac, uint8_t *key, uint8_t *data, uint32_t len)
{
  uint8_t ipad[64U];
  for (uint32_t _i = 0U; _i < (uint32_t)64U; ++_i)
    ipad[_i] = (uint8_t)0x36U;
  uint8_t opad[64U];
  for (uint32_t _i = 0U; _i < (uint32_t)64U; ++_i)
    opad[_i] = (uint8_t)0x5cU;
  Hacl_Impl_HMAC_SHA2_256_xor_bytes_inplace(ipad, key, (uint32_t)64U);
  uint32_t state0[137U] = { 0U };
  uint32_t n0 = len / (uint32_t)64U;
  uint32_t r0 = len % (uint32_t)64U;
  uint8_t *blocks0 = data;
  uint8_t *last0 = data + n0 * (uint32_t)64U;
  Hacl_Impl_SHA2_256_init(state0);
  Hacl_Impl_SHA2_256_update(state0, ipad);
  Hacl_Impl_SHA2_256_update_multi(state0, blocks0, n0);
  Hacl_Impl_SHA2_256_update_last(state0, last0, r0);
  uint8_t *hash0 = ipad;
  Hacl_Impl_SHA2_256_finish(state0, hash0);
  uint8_t *s4 = ipad;
  Hacl_Impl_HMAC_SHA2_256_xor_bytes_inplace(opad, key, (uint32_t)64U);
  uint32_t state1[137U] = { 0U };
  Hacl_Impl_SHA2_256_init(state1);
  Hacl_Impl_SHA2_256_update(state1, opad);
  Hacl_Impl_SHA2_256_update_last(state1, s4, (uint32_t)32U);
  Hacl_Impl_SHA2_256_finish(state1, mac);
}

static void IPE_FUNC
Hacl_Impl_HMAC_SHA2_256_hmac(
  uint8_t *mac,
  uint8_t *key,
  uint32_t keylen,
  uint8_t *data,
  uint32_t datalen
)
{
  uint8_t nkey[64U];
  for (uint32_t _i = 0U; _i < (uint32_t)64U; ++_i)
    nkey[_i] = (uint8_t)0x00U;
  if (keylen <= (uint32_t)64U)
      private_memcpy(nkey, key, keylen * sizeof key[0U]);
  else
  {
    uint8_t *nkey0 = nkey;
    Hacl_Impl_SHA2_256_hash(nkey0, key, keylen);
  }
  Hacl_Impl_HMAC_SHA2_256_hmac_core(mac, nkey, data, datalen);
}

void IPE_FUNC hmac_core(uint8_t *mac, uint8_t *key, uint8_t *data, uint32_t len)
{
  Hacl_Impl_HMAC_SHA2_256_hmac_core(mac, key, data, len);
}

void IPE_FUNC hmac(uint8_t *mac, uint8_t *key, uint32_t keylen, uint8_t *data, uint32_t datalen)
{
  Hacl_Impl_HMAC_SHA2_256_hmac(mac, key, keylen, data, datalen);
}

uint8_t IPE_CONST persistent_key[65] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

// example: attest the entire RAM (2 kB, starting at address 0x1000)
#define ATTEST_DATA_ADDR 0x1000
#define ATTEST_SIZE 0x0800

int IPE_ENTRY attest(void)
{
  uint8_t key[64] = {0};
  for (int i = 0; i < 64; ++ i)
  {
    key[i] = persistent_key[i];
  }

  hmac((uint8_t *) key, (uint8_t *) key, (uint32_t) 64, (uint8_t *) mac_region, (uint32_t) 32);
  hmac((uint8_t *) mac_region, (uint8_t *) key, (uint32_t) 32, (uint8_t *) ATTEST_DATA_ADDR, (uint32_t) ATTEST_SIZE);

  return signal_done(3);
}
