#!/bin/bash

make -C /openipe/core/sim/rtl_sim/src-c/ipe-hello

cd /pandora
source ./venv/bin/activate
./pandora.py run -c config-debugging.ini /openipe/core/sim/rtl_sim/src-c/ipe-hello/ipe-hello.elf

mkdir -p /openipe/logs/symbolic_ipe/
cp -r /pandora/logs/debugging_logs/* /openipe/logs/symbolic_ipe/
