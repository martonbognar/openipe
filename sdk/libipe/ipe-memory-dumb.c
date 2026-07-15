#include "ipe-memory.h"
#include "sim_io.h"

#include <stdbool.h>


#define NB_MAX_BLOCKS 100

extern uint16_t ipe_heap_START[], ipe_heap_END[];

const  uint16_t ipe_heap_start = (uint16_t)ipe_heap_START;
const uint16_t ipe_heap_end = (uint16_t)ipe_heap_END;

uint16_t IPE_VAR ind_block = 0;


void initialise_heap(void){}
void ipe_free(void * pointer){}


void* ipe_malloc(uint16_t memorySize){
    if(ind_block >= NB_MAX_BLOCKS)
        return NULL;

    uint16_t block_size = (ipe_heap_end - ipe_heap_start) / NB_MAX_BLOCKS;
    if(memorySize > block_size)
        return NULL;

    return (void*)ipe_heap_start + block_size * ind_block++;
}


void* ipe_calloc(uint16_t elementCount, uint16_t elementSize){
    if(ind_block >= NB_MAX_BLOCKS)
        return NULL;

    uint16_t block_size = (ipe_heap_end - ipe_heap_start) / NB_MAX_BLOCKS;
    uint16_t total_to_alloc = elementCount * elementSize;
    if(total_to_alloc > block_size)
        return NULL;

    return (void*)ipe_heap_start + block_size * ind_block++;
}


void* ipe_realloc(void * pointer, uint16_t memorySize){
    int16_t block_size = (ipe_heap_end - ipe_heap_start) / NB_MAX_BLOCKS;
    if(memorySize > block_size)
        return NULL;

    return pointer;
}
