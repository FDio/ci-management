#!/bin/bash

# execute csit bootstrap script if it exists
if [ ! -e bootstrap-vpp-honeycomb.sh ]
then
    echo 'ERROR: No bootstrap-vpp-honeycomb.sh found'
    exit 1
else
    # make sure that bootstrap.sh is executable
    chmod +x bootstrap-vpp-honeycomb.sh
    # run the script
    ./bootstrap-vpp-honeycomb.sh
fi

# vim: ts=4 ts=4 sts=4 et :
