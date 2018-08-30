#!/bin/bash
MAKE_PARALLEL_FLAGS="MAKE_PARALLEL_FLAGS='-j 4'"
if [[ -z ${JOB_CPU_LIMIT+x} ]]
then
    echo "JOB_CPU_LIMIT is not set, using $MAKE_PARALLEL_FLAGS"
elif [[ -z ${HOST_CPU_LIMIT+x} ]]
then
    echo "HOST_CPU_LIMIT is not set, using $MAKE_PARALLEL_FLAGS"
else
    MAX_JOBS=$(expr $HOST_CPU_LIMIT / $JOB_CPU_LIMIT)
    ALL_CORES=$(grep -c processor /proc/cpuinfo)
    CORES=$(expr $ALL_CORES / $MAX_JOBS)
    MAKE_PARALLEL_FLAGS="MAKE_PARALLEL_FLAGS='-j $CORES' TEST_JOBS=$CORES"
fi
