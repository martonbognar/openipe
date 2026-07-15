#ifndef IPE_MEMORY_H
#define IPE_MEMORY_H

#include <stddef.h>
#include "ipe_support.h"

IPE_FUNC void initialise_heap(void);
IPE_FUNC void* ipe_malloc(uint16_t memorySize);
IPE_FUNC void* ipe_calloc(uint16_t elementCount, uint16_t elementSize);
IPE_FUNC void* ipe_realloc(void * pointer, uint16_t memorySize);
IPE_FUNC void ipe_free(void * pointer);

#endif
