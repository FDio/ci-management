#!/bin/bash
CORES=4
if [[ -z ${NODE_NAME+x} || -z ${NODE_LABELS+x} ]]
then
    echo "NODE_NAME or NODE_LABELS is not set, using defaults for parallel build/test"
else
    for NODE_LABEL in $NODE_LABELS
    do
        # NODE_LABELS is jenkins-SOMEHEX and the label we're looking for
        # NODE_NAME is jenkins-SOMEHEX
        if [[ $NODE_NAME -ne $NODE_LABEL ]]
        then
            # Found label such as ubuntu1604arm-us
            break
        fi
    done

    if [[ $NODE_LABEL -eq 'ubuntu1604arm-us' ]]
    then
        CORES=16
    fi
fi

MAKE_PARALLEL_FLAGS="MAKE_PARALLEL_FLAGS='-j $CORES' TEST_JOBS=$CORES"

echo "Using $MAKE_PARALLEL_FLAGS for parallel build/test"

export MAKE_PARALLEL_FLAGS="-j $CORES"
TEST_JOBS=$CORES
