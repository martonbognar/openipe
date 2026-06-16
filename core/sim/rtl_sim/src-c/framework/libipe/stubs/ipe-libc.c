/* 
 * Complete stubs for libc
 * Most of the compiler support routines used by GCC are present in libgcc, 
 * but there are a few exceptions. GCC requires the freestanding environment 
 * provide memcpy, memmove, memset and memcmp. Contrary to the standards covering 
 * memcpy GCC expects the case of an exact overlap of source and 
 * destination to work and not invoke undefined behavior.
 * Source: https://gcc.gnu.org/onlinedocs/gcc/Standards.html
*/

#include "../ipe_support.h"

typedef unsigned int size_t;

void * IPE_FUNC
__ipememset (void *d, int c, size_t n)
{
  char *dst = (char *) d;
  while (n--)
    *dst++ = c;
  return (char *) d;
}


void * IPE_FUNC
__ipememcpy (void *d, const void *s, size_t n)
{
  char *dst = (char *) d;
  const char *src = (const char *) s;
  while (n--)
    *dst++ = *src++;
  return (char *) d;
}


void * IPE_FUNC
__ipememmove(void *dst, const void *src, size_t len)
{
  char *d = dst;
  const char *s = src;

  if (s < d && d < s + len)
    {
      /* Destructive overlap...have to copy backwards.  */
      s += len;
      d += len;

      while (len--)
	*--d = *--s;

      return dst;
    }
  else
    return __ipememcpy(dst, src, len);
}


int IPE_FUNC
__ipememcmp (const void *str1, const void *str2, size_t count)
{
  const unsigned char *s1 = str1;
  const unsigned char *s2 = str2;

  while (count-- > 0)
    {
      if (*s1++ != *s2++)
	  return s1[-1] < s2[-1] ? -1 : 1;
    }
  return 0;
}
