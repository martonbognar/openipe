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


./gen_linker_def.sh ipe_linker.x "../bin/template_defs.asm" $pmemsize $dmemsize $persize $bmemsize


echo ""
echo "\$ $MSPGCC_PFX-as      -alsm ../src/ipe/$1 -o bootcode.o > bmem.l43"
$MSPGCC_PFX-as      -alsm ../src/ipe/$1 -I../../../../sdk/libipe/stubs -o bootcode.o    > bmem.l43
echo "\$ $MSPGCC_PFX-ld      -L. -T pmem.x bootcode.o -o bootcode.elf"
$MSPGCC_PFX-ld      -L. -T pmem.x   bootcode.o    -o bootcode.elf
echo ""
