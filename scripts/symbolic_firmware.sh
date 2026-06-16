#!/bin/bash

make -C /openipe/core/sim/verilator build/bootcode.elf

cd /pandora
source ./venv/bin/activate
./pandora.py run -c config-debugging.ini /openipe/core/sim/verilator/build/bootcode.elf

mkdir -p /openipe/logs/symbolic_firmware/
cp -r /pandora/logs/debugging_logs/* /openipe/logs/symbolic_firmware/
