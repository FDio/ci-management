#!/bin/bash
CORES=4
if [[ $(uname -m) == 'aarch64' ]]
then
    CORES=16
fi

echo "Using MAKE_PARALLEL_FLAGS='-j $CORES' TEST_JOBS=$CORES for parallel build/test"

export MAKE_PARALLEL_FLAGS="-j $CORES"
export TEST_JOBS=$CORES
