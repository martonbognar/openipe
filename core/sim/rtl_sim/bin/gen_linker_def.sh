#!/bin/bash

###############################################################################
#               Generate the linker definition file                           #
###############################################################################

EXPECTED_ARGS=6
if [ $# -ne $EXPECTED_ARGS ]; then
  echo "ERROR    : wrong number of arguments"
  echo "USAGE    : gen_linker_def.sh <linker script> <assembler define>  <prog mem size> <data mem size> <peripheral addr space size> <bootcode mem size>"
  exit 1
fi


BMEM_TOTAL_SIZE=$6
PER_SIZE=$5
DMEM_SIZE=$4
PMEM_SIZE=$3
PMEM_BASE=$((0x10000-$PMEM_SIZE))
STACK_INIT=$((PER_SIZE+0x0080))
BMEM_BASE=$((PER_SIZE+DMEM_SIZE))
BMEM_IVT_BASE=$((BMEM_BASE+BMEM_TOTAL_SIZE-0x24))
BMEM_TRAMPOLINE_BASE=$((BMEM_BASE+BMEM_TOTAL_SIZE-0x4))

cp  $1  ./pmem.x
cp  $2  ./pmem_defs.asm
sed -ie "s/PMEM_BASE/$PMEM_BASE/g"         pmem.x
sed -ie "s/PMEM_SIZE/$PMEM_SIZE/g"         pmem.x
sed -ie "s/BMEM_BASE/$BMEM_BASE/g"         pmem.x
sed -ie "s/BMEM_IVT_BASE/$BMEM_IVT_BASE/g"         pmem.x
sed -ie "s/BMEM_TRAMPOLINE_BASE/$BMEM_TRAMPOLINE_BASE/g"         pmem.x
sed -ie "s/BMEM_TOTAL_SIZE/$BMEM_TOTAL_SIZE/g"         pmem.x
sed -ie "s/DMEM_SIZE/$DMEM_SIZE/g"         pmem.x
sed -ie "s/PER_SIZE/$PER_SIZE/g"           pmem.x
sed -ie "s/STACK_INIT/$STACK_INIT/g"       pmem.x

sed -ie "s/PMEM_SIZE/$PMEM_SIZE/g"         pmem_defs.asm
sed -ie "s/PER_SIZE_HEX/$PER_SIZE/g"       pmem_defs.asm
sed -ie "s/BMEM_BASE_VAL/$BMEM_BASE/g" pmem_defs.asm
sed -ie "s/BMEM_TOTAL_SIZE/$BMEM_TOTAL_SIZE/g"         pmem_defs.asm
if [ $MSPGCC_PFX == "msp430-elf" ]; then
    sed -ie "s/PER_SIZE/.data/g"           pmem_defs.asm
    sed -ie "s/PMEM_BASE_VAL/.text/g"      pmem_defs.asm
    sed -ie "s/PMEM_EDE_SIZE/0/g"          pmem_defs.asm
else
    sed -ie "s/PER_SIZE/$PER_SIZE/g"       pmem_defs.asm
    sed -ie "s/PMEM_BASE_VAL/$PMEM_BASE/g" pmem_defs.asm
    sed -ie "s/PMEM_EDE_SIZE/$PMEM_SIZE/g" pmem_defs.asm
fi
