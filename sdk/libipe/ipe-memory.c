#include "ipe-memory.h"
#include "sim_io.h"

#include <stdbool.h>

void * __ipememcpy (void *d, const void *s, size_t n);
void * __ipememset (void *d, int c, size_t n);

extern uint16_t ipe_heap_START[], ipe_heap_END[];
uint16_t ipe_heap_start = (uint16_t)ipe_heap_START;
uint16_t ipe_heap_end = (uint16_t)ipe_heap_END;


typedef struct _block_header
{
    char is_allocated;
    uint16_t block_size;
} block_header_t;


void initialise_heap(void){
    uint16_t heap_size = ipe_heap_end - ipe_heap_start - sizeof(block_header_t);
    block_header_t* base_header = (block_header_t*)ipe_heap_start;

    base_header->is_allocated = 0;
    base_header->block_size = heap_size;
}


IPE_FUNC int search_empty_block(block_header_t** header, uint16_t memorySize){
    while(*header < (block_header_t*)ipe_heap_end){
        if(!(*header)->is_allocated && (*header)->block_size >= memorySize)
            return 0;

        uint16_t next_addr = (uint16_t)*header + (*header)->block_size + sizeof(block_header_t);
        *header = (block_header_t*)next_addr;
    }

    return 1;
}


void IPE_FUNC ipe_alloc_buffer(
    block_header_t* header, uint16_t memorySize,
    bool do_copy, void* origin, uint16_t copy_size){
    if(do_copy){
        __ipememcpy(header + 1, origin, copy_size);
    }
    
    uint16_t new_block_size = memorySize;
    if(memorySize + sizeof(block_header_t) <= header->block_size){
        uint16_t next_addr = (uint16_t)header + memorySize + sizeof(block_header_t);
        block_header_t* next_header = (block_header_t*)next_addr;

        next_header->is_allocated = 0;
        next_header->block_size = header->block_size - memorySize - sizeof(block_header_t);
    } else{
        new_block_size = header->block_size;
    }

    header->is_allocated = 1;
    header->block_size = new_block_size;
}


void* ipe_malloc(uint16_t memorySize){
    block_header_t* header = (block_header_t*)ipe_heap_start;

    if(search_empty_block(&header, memorySize) != 0)
        return NULL;

    ipe_alloc_buffer(header, memorySize, false, NULL, 0);
    
    return header + 1;
}


void* ipe_calloc(uint16_t elementCount, uint16_t elementSize){
    if(elementCount == 0 || elementSize == 0)
        return ipe_malloc(0);

    uint64_t total_to_alloc = elementCount * elementSize;
    if(total_to_alloc < elementCount || total_to_alloc < elementSize)
        return NULL;

    void* ptr = ipe_malloc(total_to_alloc);
    __ipememset(ptr, 0, total_to_alloc);

    return ptr;
}


void* ipe_realloc(void * pointer, uint16_t memorySize){
    block_header_t* ptr_header = (block_header_t*)pointer - 1;
    if(memorySize <= ptr_header->block_size)
        return pointer;

    uint16_t next_addr = (uint16_t)ptr_header + ptr_header->block_size + sizeof(block_header_t);
    block_header_t* next_header = (block_header_t*)next_addr;

    if(
        !next_header->is_allocated && 
        ptr_header->block_size + next_header->block_size + sizeof(block_header_t) >= memorySize
    ){
            uint16_t new_block_size = memorySize;
            if(memorySize + sizeof(block_header_t) <= ptr_header->block_size + next_header->block_size){
               uint16_t next_addr = (uint16_t)ptr_header + memorySize + sizeof(block_header_t);
                block_header_t* next_header = (block_header_t*)next_addr;

                next_header->is_allocated = 0;
                next_header->block_size = ptr_header->block_size - memorySize - sizeof(block_header_t);
            } else{
                new_block_size = ptr_header->block_size;
            }
            ptr_header->block_size = new_block_size;
            return pointer;
    }
    // In this case we need to find another block
    // We're sure that the malloc won't corrupt the actual buffer data
    ipe_free(pointer);
    block_header_t* header = (block_header_t*)ipe_heap_start;

    if(search_empty_block(&header, memorySize) != 0)
        return NULL;

    ipe_alloc_buffer(header, memorySize, true, pointer, ptr_header->block_size);

    return header + 1;

    

}


void IPE_FUNC merge_unused_blocks(block_header_t* header){
    uint16_t next_addr = (uint16_t)header + header->block_size + sizeof(block_header_t);
    block_header_t* next_header = (block_header_t*)next_addr;

    while(next_header != (block_header_t*)ipe_heap_end && !next_header->is_allocated){
        header->block_size += next_header->block_size + sizeof(block_header_t);

        next_addr = (uint16_t)header + header->block_size + sizeof(block_header_t);
        next_header = (block_header_t*)next_addr;
    }
}


void ipe_free(void * pointer){
    block_header_t* ptr_header = (block_header_t*)pointer - 1;
    ptr_header->is_allocated = 0;

    merge_unused_blocks(ptr_header);
}
