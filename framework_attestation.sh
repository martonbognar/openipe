#!/bin/bash

set -ex

# run framework on initial input file
cd /openipe/core/sim/rtl_sim/src-c/ipe-hmac
../framework/translator.py ipe.c

# remove original entry function from the file and replace it with the generated one
sed -i '/int IPE_ENTRY attest(void)/Q' ipe.c
cat output/ipe.c >> ipe.c

# run simulation
cd /openipe/core/sim/rtl_sim/run/
./run_c ipe-hmac
