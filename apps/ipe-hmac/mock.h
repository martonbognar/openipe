#ifndef MOCK_H_
#define MOCK_H_

typedef   signed char    int8_t;
typedef unsigned char   uint8_t;
typedef          int    int16_t;
typedef unsigned int   uint16_t;
typedef          long   int32_t;
typedef unsigned long  uint32_t;
typedef          long long  int64_t;
typedef unsigned long long uint64_t;

typedef  int8_t   int_least8_t;
typedef uint8_t  uint_least8_t;
typedef  int16_t  int_least16_t;
typedef uint16_t uint_least16_t;
typedef  int32_t  int_least32_t;
typedef uint32_t uint_least32_t;
typedef  int64_t  int_least64_t;
typedef uint64_t uint_least64_t;

#define  INT64_C(value) ((int_least64_t)(value))
#define UINT64_C(value) ((uint_least64_t)(value))

#define false   0
#define true    1

#define bool    _Bool

#endif /* MOCK_H_ */
