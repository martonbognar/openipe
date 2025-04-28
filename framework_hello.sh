#!/bin/bash

set -ex

# run framework on initial input file
cd /openipe/core/sim/rtl_sim/src-c/ipe-hello
../framework/translator.py main.c

# remove original entry function from the file and replace it with the generated one
sed -i '/int IPE_ENTRY ipe_func(int a)/Q' main.c
cat output/main.c >> main.c

# run simulation
cd /openipe/core/sim/rtl_sim/run/
./run_c ipe-hello
