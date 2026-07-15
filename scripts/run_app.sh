#!/bin/bash

# Build the Verilator simulator and the given IPE application, then run the
# application on the simulator (loading the IPE bootcode as firmware).
#
# Usage: ./scripts/run_app.sh <app-name>
# where <app-name> is a directory under app/ (e.g. ipe-hello, ipe-hmac).
#
# Exits non-zero if the simulator fails or the application reports a failure.
# Note: the simulator halts with success on CPUOFF even when an ASSERT fails,
# so we additionally scan the output for a "FAIL" line.

set -e

APP="${1:?usage: $0 <app-name>}"
USE_STEP="${2:-0}"

SIM_DIR=/openipe/core/sim/verilator

if [ $USE_STEP -eq 1 ]; then 
    make -C "$SIM_DIR" clean

    export BOOTCODE_NAME=bootcode-clean-irq.s43
    make -C "$SIM_DIR" __IPE_IRQ_FW=1
else
    make -C "$SIM_DIR"
fi

make -C "/openipe/app/$APP" clean
make -C "/openipe/app/$APP"

# Stream output live (line-buffered) while also capturing it for the FAIL check.
log=$(mktemp)
stdbuf -oL -eL "$SIM_DIR/build/ipe-sim" \
    --firmware "$SIM_DIR/build/bootcode.elf" \
    --pmem-size 49152 \
    "/openipe/app/$APP/$APP.elf" 2>&1 | tee "$log"
ret=${PIPESTATUS[0]}

if [ "$ret" -ne 0 ] || grep -q "^FAIL" "$log"; then
    rm -f "$log"
    exit 1
fi
rm -f "$log"
