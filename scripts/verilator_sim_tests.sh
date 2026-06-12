#!/bin/bash
# Build ipe-sim + bootcode, then compile and simulate each src-c/ipe program.
# Programs terminate with EXIT() (sets CPUOFF), so ipe-sim exits 0 on success.

set -e

SIM_DIR=/openipe/core/sim/verilator
SRC_C=/openipe/core/sim/rtl_sim/src-c

echo "=== Building ipe-sim and bootcode ==="
make -C "$SIM_DIR"

IPE_SIM="$SIM_DIR/build/ipe-sim"
BOOTCODE="$SIM_DIR/build/bootcode.elf"

PASS=0
FAIL=0

for prog in ipe-hello ipe-mul ipe-hmac ipe-simple-rsa; do
    echo ""
    echo "=== Building $prog ==="
    (cd "$SRC_C/$prog" && make clean && make)

    echo "=== Simulating $prog ==="
    set +e
    "$IPE_SIM" --firmware "$BOOTCODE" -c 100000 "$SRC_C/$prog/$prog.elf"
    ret=$?
    set -e

    if [ "$ret" -eq 0 ]; then
        echo "PASS: $prog"
        PASS=$((PASS+1))
    else
        echo "FAIL: $prog (exit $ret)"
        FAIL=$((FAIL+1))
    fi
done

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
