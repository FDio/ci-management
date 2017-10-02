#!/bin/bash

export TEST_TAG="PERFTEST_${TYPE^^}"

# execute csit bootstrap script if it exists
if [ ! -e bootstrap-verify-perf-ligato.sh ]
then
    echo 'ERROR: No bootstrap-verify-perf-ligato.sh found'
    exit 1
fi

# make sure that bootstrap-verify-perf-ligato.sh is executable
chmod +x bootstrap-verify-perf-ligato.sh

# get commit ID from name of stable ver
VPP_BUILD_COMMIT="$( expr match `cat VPP_STABLE_VER_UBUNTU` '.*g\(.*\)~.*' )"

# run the script
./bootstrap-verify-perf-ligato.sh ${VPP_BUILD_COMMIT}

# vim: ts=4 ts=4 sts=4 et :
