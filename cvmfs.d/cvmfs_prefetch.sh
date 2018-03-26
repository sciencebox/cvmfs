#!/bin/bash

source /cvmfs/sft.cern.ch/lcg/views/$SOFTWARE_STACK/$PLATFORM/setup.sh
timeout 60s python -m ipykernel > /dev/null 2>&1 || true
timeout 60s python -m JupyROOT.kernel.rootkernel > /dev/null 2>&1 || true
