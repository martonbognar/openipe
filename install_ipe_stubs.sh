#!/bin/bash

msp_gcc_root=/msp430-gcc
if [ $# -eq 1 ]; then
    msp_gcc_root=$1
fi

cd ${msp_gcc_root}/lib/gcc/msp430-elf/${MSPGCC_VERSION_MAJOR}/430
for lib in libgcc libmul_none; do
    # unique temp dir per lib ($$=PID avoids collisions)
    dir=/tmp/ar-$$-${lib}
    # create IPE-prefixed variant with renamed symbols and sections
    msp430-elf-objcopy --prefix-symbols=__ipe --prefix-alloc-sections=.ipe_func ${lib}.a ${lib}-ipe.a && \
    # extract into separate dirs (ar cannot directly merge archives)
    mkdir -p ${dir}/orig ${dir}/ipe
    msp430-elf-ar x ${lib}.a    --output ${dir}/orig
    msp430-elf-ar x ${lib}-ipe.a --output ${dir}/ipe
    # repack both sets of objects into a single merged archive
    rm ${lib}.a
    msp430-elf-ar rcs ${lib}.a ${dir}/orig/*.o ${dir}/ipe/*.o
    rm -rf ${dir};
done
