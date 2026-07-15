#ifndef BSL_H
#define BSL_H

#include "libipe/ipe_support.h"


char IPE_ENTRY BSL430_unlock_BSL_unbalanced();
char IPE_ENTRY BSL430_unlock_BSL_balanced();

#define SUCCESSFUL_OPERATION 0x00
#define BSL_PASSWORD_ERROR 0x05


// Using IPE vectors here
#define INTERRUPT_VECTOR_START 0xE3E0
#define INTERRUPT_VECTOR_END   0xE3FF
#define BSL_PASSWORD_LENGTH    (INTERRUPT_VECTOR_END - INTERRUPT_VECTOR_START + 1)

#endif
