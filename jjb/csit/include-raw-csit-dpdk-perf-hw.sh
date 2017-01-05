#!/bin/bash

export TEST_TAG="PERFTEST_${TYPE^^}"

# execute csit bootstrap script if it exists
if [ ! -e bootstrap-verify-perf-DPDK.sh ]
then
    echo 'ERROR: No bootstrap-verify-perf-DPDK.sh found'
    exit 1
fi

# make sure that bootstrap-verify-perf.sh is executable
chmod +x bootstrap-verify-perf-DPDK.sh
# run the script
./bootstrap-verify-perf-DPDK.sh *.deb

# vim: ts=4 ts=4 sts=4 et :
