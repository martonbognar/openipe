#ifndef SIM_IO_H
#define SIM_IO_H

#include "ipe_support.h"

/* NOTE: we don't include the full <stdio.h> here so as to not crash pycparser */
int puts(const char *s);
int printf(const char *restrict format, ...);

/* UART_TXD at byte address 0x0084 (omsp_uart_print BASE_ADDR=0x0080, TXD offset=4) */
#define UART_TXD ((volatile uint8_t *)0x0084)

/* Implemented in sim_io.c: routes the printf()/puts() backend to the UART. */
int write(int fd, const char *buf, int len);

// Used since inline may not work with -0s compilation flag
static inline int IPE_FUNC ipe_putchar(int c)
{
    *UART_TXD = (uint8_t)c;
    return c;
}


static inline int putchar(int c)
{
    *UART_TXD = (uint8_t)c;
    return c;
}


static inline int IPE_FUNC ipe_puts(const char *s)
{
    while (*s) ipe_putchar(*s++);
    ipe_putchar('\n');
    return 0;
}

#define ASSERT(cond, msg) \
    do { if (!(cond)) { puts("FAIL: " msg); EXIT(); } puts("ok:   " msg); } while (0)

#define IPE_ASSERT(cond, msg) \
    do { if (!(cond)) { ipe_puts("FAIL: " msg); EXIT(); } ipe_puts("ok:   " msg); } while (0)

#define PASS() do { puts("PASS"); EXIT(); } while (0)

#endif /* SIM_IO_H */
