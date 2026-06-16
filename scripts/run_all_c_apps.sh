#!/bin/bash

app_dir=`ls -d apps/*/`

for app in $app_dir
do
  echo "Running test in $app"
  openipe-sim.py $app
done
