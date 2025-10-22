#!/bin/bash

cd /pandora
./pandora.py run -c config-debugging.ini /openipe/core/sim/rtl_sim/run/bmem.elf

mkdir -p /openipe/logs/symbolic_firmware/
cp -r /pandora/logs/debugging_logs/* /openipe/logs/symbolic_firmware/