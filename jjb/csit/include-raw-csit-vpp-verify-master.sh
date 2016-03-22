#!/bin/bash

# execute csit bootstrap script if it exists
if [ -e bootstrap-verify-master.sh ]
then
    # make sure that bootstrap.sh is executable
    chmod +x bootstrap-verify-master.sh
    # run the script
    ./bootstrap-verify-master.sh
else
    echo 'ERROR: No bootstrap-verify-master.sh found'
    exit 1
fi

# vim: ts=4 ts=4 sts=4 et :
