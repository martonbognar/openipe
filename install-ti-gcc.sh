#!/bin/bash

export MSPGCC_VERSION_MAJOR=9.3.1
export MSPGCC_VERSION_MINOR=${MSPGCC_VERSION_MAJOR}.11
export MSPGCC_SUPPORT_VERSION=1.212
export MSPGCC_URL="https://dr-download.ti.com/software-development/ide-configuration-compiler-or-debugger/MD-LlCjWuAbzH/9.3.1.2"

wget ${MSPGCC_URL}/msp430-gcc-${MSPGCC_VERSION_MINOR}_linux64.tar.bz2
tar xjf msp430-gcc-${MSPGCC_VERSION_MINOR}_linux64.tar.bz2
mv msp430-gcc-${MSPGCC_VERSION_MINOR}_linux64 msp430-gcc

# Install headers
wget ${MSPGCC_URL}/msp430-gcc-support-files-${MSPGCC_SUPPORT_VERSION}.zip
unzip msp430-gcc-support-files-${MSPGCC_SUPPORT_VERSION}.zip
cp -a msp430-gcc-support-files/include/*.h msp430-gcc/msp430-elf/include
cp -a msp430-gcc-support-files/include/*.ld msp430-gcc/msp430-elf/lib

rm -fr msp430-gcc-support-files msp430-gcc-${MSPGCC_VERSION_MINOR}_linux64.tar.bz2 msp430-gcc-support-files-${MSPGCC_SUPPORT_VERSION}.zip

cd msp430-gcc/lib/gcc/msp430-elf/${MSPGCC_VERSION_MAJOR}/430
export PATH="$PATH:../../../../../bin"

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
