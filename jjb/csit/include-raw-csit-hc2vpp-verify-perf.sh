#!/bin/bash

# execute csit bootstrap script if it exists
if [[ ! -e bootstrap-hc2vpp-perf.sh ]]
then
    echo 'ERROR: No bootstrap-hc2vpp-perf.sh found'
    exit 1
else
    # make sure that bootstrap.sh is executable
    chmod +x bootstrap-hc2vpp-perf.sh
    # run the script
    ./bootstrap-hc2vpp-perf.sh ${STREAM} ${OS}
fi

# vim: ts=4 ts=4 sts=4 et :
