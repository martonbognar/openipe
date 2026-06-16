#ifndef SIM_IO_H
#define SIM_IO_H

#include "ipe_support.h"

/* UART_TXD at byte address 0x0084 (omsp_uart_print BASE_ADDR=0x0080, TXD offset=4) */
#define UART_TXD ((volatile uint8_t *)0x0084)

static inline int putchar(int c)
{
    *UART_TXD = (uint8_t)c;
    return c;
}

static inline int puts(const char *s)
{
    while (*s) putchar(*s++);
    putchar('\n');
    return 0;
}

#define ASSERT(cond, msg) \
    do { if (!(cond)) { puts("FAIL: " msg); EXIT(); } puts("ok:   " msg); } while (0)

#define PASS() do { puts("PASS"); EXIT(); } while (0)

#endif /* SIM_IO_H */
