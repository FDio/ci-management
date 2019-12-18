#!/bin/bash

# execute  nsh_sfc bootstrap script if it exists
if [ ! -e bootstrap-verify-perf-nsh_sfc.sh ]
then
    echo 'ERROR: No bootstrap-verify-perf-nsh_sfc.sh found'
    exit 1
fi

# make sure that bootstrap-verify-perf.sh is executable
chmod +x bootstrap-verify-perf-nsh_sfc.sh
# run the script
if [ ${STREAM} == 'master' ]; then
    ./bootstrap-verify-perf-nsh_sfc.sh ${STREAM} ${OS}
else
    ./bootstrap-verify-perf-nsh_sfc.sh 'stable.'${STREAM} ${OS}
fi

# vim: ts=4 ts=4 sts=4 et :
