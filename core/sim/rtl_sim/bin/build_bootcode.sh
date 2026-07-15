#!/bin/bash

###############################################################################
#                            Parameter Check                                  #
###############################################################################
EXPECTED_ARGS=1
if [ $# -ne $EXPECTED_ARGS ]; then
  echo "ERROR    : wrong number of arguments"
  echo "USAGE    : build_bootcode <bootcode name>"
  echo "Example  : build_bootcode bootcode.s43"
  exit
fi

if command -v msp430-gcc >/dev/null; then
    MSPGCC_PFX=msp430
else
    MSPGCC_PFX=msp430-elf
fi

###############################################################################
#                               Cleanup                                       #
###############################################################################
echo "Cleanup..."
rm -rf *.vcd
rm -rf *.vpd
rm -rf *.trn
rm -rf *.dsn
rm -rf pmem*

incfile=../../../rtl/verilog/openMSP430_defines.v;
# Make local copy of the openMSP403 configuration file
# and prepare it for MSPGCC preprocessing
cp  $incfile  ../run/pmem.h
sed -ie 's/`ifdef/#ifdef/g'         ../run/pmem.h
sed -ie 's/`else/#else/g'           ../run/pmem.h
sed -ie 's/`endif/#endif/g'         ../run/pmem.h
sed -ie 's/`define/#define/g'       ../run/pmem.h
sed -ie 's/`include/\/\/#include/g' ../run/pmem.h
sed -ie 's/`//g'                    ../run/pmem.h
sed -ie "s/'//g"                    ../run/pmem.h

# Use MSPGCC preprocessor to extract the Program, Data
# and Peripheral memory sizes
echo "\$ $MSPGCC_PFX-gcc -E -P -x c omsp_config.sh > pmem.sh"
$MSPGCC_PFX-gcc -E -P -x c omsp_config.sh > pmem.sh

# Source the extracted configuration file
if [[ $(uname -s) == CYGWIN* ]];
then
dos2unix pmem.sh
fi
source   pmem.sh

cp ipe_linker.x pmem.x
PMEM_BASE=$((0x10000-$pmemsize))
STACK_INIT=$((persize+0x0080))
BMEM_BASE=$((persize+dmemsize))
BMEM_IVT_BASE=$((BMEM_BASE+bmemsize-0x24))
BMEM_TRAMPOLINE_BASE=$((BMEM_BASE+bmemsize-0x4))
sed -ie "s/PMEM_BASE/$PMEM_BASE/g"         pmem.x
sed -ie "s/PMEM_SIZE/$pmemsize/g"         pmem.x
sed -ie "s/BMEM_BASE/$BMEM_BASE/g"         pmem.x
sed -ie "s/BMEM_IVT_BASE/$BMEM_IVT_BASE/g"         pmem.x
sed -ie "s/BMEM_TRAMPOLINE_BASE/$BMEM_TRAMPOLINE_BASE/g"         pmem.x
sed -ie "s/BMEM_TOTAL_SIZE/$bmemsize/g"         pmem.x
sed -ie "s/DMEM_SIZE/$dmemsize/g"         pmem.x
sed -ie "s/PER_SIZE/$persize/g"           pmem.x
sed -ie "s/STACK_INIT/$STACK_INIT/g"       pmem.x

# Compile bootcode firmware
echo "Compile, link & generate bootcode IHEX file (Bootcode Memory: $bmemsize B)"

cp  "../bin/template_defs.asm"  ./pmem_defs.asm
sed -ie "s/PMEM_SIZE/$pmemsize/g"         pmem_defs.asm
sed -ie "s/PER_SIZE_HEX/$persize/g"       pmem_defs.asm
sed -ie "s/BMEM_BASE_VAL/$BMEM_BASE/g" pmem_defs.asm
sed -ie "s/BMEM_TOTAL_SIZE/$bmemsize/g"         pmem_defs.asm
if [ $MSPGCC_PFX == "msp430-elf" ]; then
    sed -ie "s/PER_SIZE/.data/g"           pmem_defs.asm
    sed -ie "s/PMEM_BASE_VAL/.text/g"      pmem_defs.asm
    sed -ie "s/PMEM_EDE_SIZE/0/g"          pmem_defs.asm
else
    sed -ie "s/PER_SIZE/$persize/g"       pmem_defs.asm
    sed -ie "s/PMEM_BASE_VAL/$PMEM_BASE/g" pmem_defs.asm
    sed -ie "s/PMEM_EDE_SIZE/$pmemsize/g" pmem_defs.asm
fi

echo ""
echo "\$ $MSPGCC_PFX-as      -alsm ../src/ipe/$1 -o bootcode.o > bmem.l43"
$MSPGCC_PFX-as      -alsm ../src/ipe/$1 -I../../../../sdk/libipe/stubs -o bootcode.o    > bmem.l43
echo "\$ $MSPGCC_PFX-ld      -L. -T pmem.x bootcode.o -o bootcode.elf"
$MSPGCC_PFX-ld      -L. -T pmem.x   bootcode.o    -o bootcode.elf
echo ""
