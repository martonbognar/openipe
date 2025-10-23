#!/bin/bash

cd /pandora
./pandora.py run -c config-debugging.ini /openipe/core/sim/rtl_sim/run/pmem.elf

mkdir -p /openipe/logs/symbolic_ipe/
cp -r /pandora/logs/debugging_logs/* /openipe/logs/symbolic_ipe/
