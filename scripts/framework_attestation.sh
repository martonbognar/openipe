#!/bin/bash

set -ex

# run framework on initial input file
cd /openipe/core/sim/rtl_sim/src-c/ipe-hmac
../framework/translator.py ipe.c

# copy ipe.c to generated_ipe.c
cp ipe.c generated_ipe.c

# remove original entry function from the generated file and replace it with the translator-generated one
sed -i '/int IPE_ENTRY attest(void)/Q' generated_ipe.c
cat output/ipe.c >> generated_ipe.c

# run simulation
cd /openipe/core/sim/rtl_sim/run/
./run_c ipe-hmac