#!/bin/bash

# execute csit bootstrap script if it exists
if [ -e bootstrap-hw-tb2.sh ]
then
    # make sure that bootstrap.sh is executable
    chmod +x bootstrap-hw-tb2.sh
    # run the script
    ./bootstrap-hw-tb2.sh
else
    echo 'ERROR: No bootstrap-hw-tb2.sh found'
    exit 1
fi

# vim: ts=4 ts=4 sts=4 et :
