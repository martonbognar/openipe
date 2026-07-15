#!/bin/bash

export SIM_DIR=/openipe/core/sim/verilator
make clean && make && $SIM_DIR/build/ipe-sim --firmware $SIM_DIR/build/bootcode.elf --pmem-size 49152 -c -1 customTLS.elf
