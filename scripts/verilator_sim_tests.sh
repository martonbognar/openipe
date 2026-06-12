#!/bin/bash
# Build ipe-sim and run all src-c/ipe programs through the Verilator simulator.
# Programs end with while(1) so timeout (exit 2) is accepted as success; only
# a simulator crash (exit 1) or missing input (exit 3) is a failure.

set -e

RUNDIR=/openipe/core/sim/rtl_sim/run
BINDIR=/openipe/core/sim/rtl_sim/bin
SRC_C=/openipe/core/sim/rtl_sim/src-c
RTLDIR=/openipe/core/rtl/verilog
SIM_DIR=/openipe/core/sim/verilator

cd "$RUNDIR"

###############################################################################
# Extract memory sizes from openMSP430_defines.v
###############################################################################
cp "$RTLDIR/openMSP430_defines.v" ./pmem.h
sed -ie 's/`ifdef/#ifdef/g'         ./pmem.h
sed -ie 's/`else/#else/g'           ./pmem.h
sed -ie 's/`endif/#endif/g'         ./pmem.h
sed -ie 's/`define/#define/g'       ./pmem.h
sed -ie 's/`include/\/\/#include/g' ./pmem.h
sed -ie 's/`//g'                    ./pmem.h
sed -ie "s/'//g"                    ./pmem.h

msp430-elf-gcc -E -P -x c "$BINDIR/omsp_config.sh" > pmem.sh
source pmem.sh   # sets pmemsize, bmemsize, dmemsize, persize

PMEM_BASE=$((0x10000-pmemsize))
STACK_INIT=$((persize+0x0080))
BMEM_BASE=$((persize+dmemsize))
BMEM_IVT_BASE=$((BMEM_BASE+bmemsize-0x24))
BMEM_TRAMPOLINE_BASE=$((BMEM_BASE+bmemsize-0x4))

###############################################################################
# Generate pmem_defs.asm (needed by bootcode.s43)
###############################################################################
cp "$BINDIR/template_defs.asm" ./pmem_defs.asm
sed -ie "s/PMEM_SIZE/$pmemsize/g"        pmem_defs.asm
sed -ie "s/PER_SIZE_HEX/$persize/g"      pmem_defs.asm
sed -ie "s/BMEM_BASE_VAL/$BMEM_BASE/g"   pmem_defs.asm
sed -ie "s/BMEM_TOTAL_SIZE/$bmemsize/g"  pmem_defs.asm
# msp430-elf: use section names instead of numeric addresses
sed -ie "s/PER_SIZE/.data/g"             pmem_defs.asm
sed -ie "s/PMEM_BASE_VAL/.text/g"        pmem_defs.asm
sed -ie "s/PMEM_EDE_SIZE/0/g"            pmem_defs.asm

###############################################################################
# Generate pmem.x (used by both app and bootcode linker)
###############################################################################
cp "$BINDIR/ipe_linker.x" pmem.x
sed -ie "s/PMEM_BASE/$PMEM_BASE/g"                   pmem.x
sed -ie "s/PMEM_SIZE/$pmemsize/g"                    pmem.x
sed -ie "s/BMEM_IVT_BASE/$BMEM_IVT_BASE/g"           pmem.x
sed -ie "s/BMEM_TRAMPOLINE_BASE/$BMEM_TRAMPOLINE_BASE/g" pmem.x
sed -ie "s/BMEM_BASE/$BMEM_BASE/g"                   pmem.x
sed -ie "s/BMEM_TOTAL_SIZE/$bmemsize/g"              pmem.x
sed -ie "s/DMEM_SIZE/$dmemsize/g"                    pmem.x
sed -ie "s/PER_SIZE/$persize/g"                      pmem.x
sed -ie "s/STACK_INIT/$STACK_INIT/g"                 pmem.x

###############################################################################
# Compile bootcode once (shared across all programs)
###############################################################################
echo "=== Compiling bootcode ==="
msp430-elf-as -alsm "$RUNDIR/../src/ipe/bootcode.s43" -o bootcode.o > bootcode.l43
msp430-elf-ld -T pmem.x bootcode.o -o bootcode.elf
echo "bootcode.elf ready"

###############################################################################
# Build ipe-sim
###############################################################################
echo "=== Building ipe-sim ==="
make -C "$SIM_DIR"
IPE_SIM="$SIM_DIR/build/ipe-sim"

###############################################################################
# Compile and simulate each program
###############################################################################
PASS=0
FAIL=0

for prog in ipe-hello ipe-mul ipe-hmac ipe-simple-rsa; do
    softdir="$SRC_C/$prog"
    elffile="$softdir/$prog.elf"

    echo ""
    echo "=== Building $prog ==="
    cp pmem.x "$softdir/pmem.x"
    (cd "$softdir" && make clean && make)

    echo "=== Simulating $prog ==="
    set +e
    "$IPE_SIM" --firmware bootcode.elf -c 500000 "$elffile"
    ret=$?
    set -e

    # exit 0 = cpuoff (clean termination), exit 2 = cycle timeout (expected for while(1) loops)
    if [ "$ret" -eq 0 ] || [ "$ret" -eq 2 ]; then
        echo "PASS: $prog (exit $ret)"
        PASS=$((PASS+1))
    else
        echo "FAIL: $prog (exit $ret)"
        FAIL=$((FAIL+1))
    fi
done

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
