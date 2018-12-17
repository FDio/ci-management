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
        if [[ $NODE_NAME != $NODE_LABEL ]]
        then
            # Found label such as ubuntu1804arm-us
            break
        fi
    done

    if [[ $NODE_LABEL == ubuntu*arm-* ]]
    then
        CORES=16
    fi
fi

echo "Using MAKE_PARALLEL_FLAGS='-j $CORES' TEST_JOBS=$CORES for parallel build/test"

export MAKE_PARALLEL_FLAGS="-j $CORES"
export TEST_JOBS=$CORES
