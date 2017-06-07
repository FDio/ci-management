#!/bin/bash

# execute csit bootstrap script if it exists
if [ ! -e bootstrap-hc2vpp-integration.sh ]
then
    echo 'ERROR: No bootstrap-hc2vpp-integration.sh found'
    exit 1
else
    # make sure that bootstrap.sh is executable
    chmod +x bootstrap-hc2vpp-integration.sh
    # run the script
    if [ ${STREAM} == 'master' ]; then
        ./bootstrap-hc2vpp-integration.sh ${STREAM} ${OS}
    else
        ./bootstrap-hc2vpp-integration.sh 'stable.'${STREAM} ${OS}
    fi
fi

# vim: ts=4 ts=4 sts=4 et :
