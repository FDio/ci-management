#!/bin/bash

# execute csit bootstrap script if it exists
if [ -e bootstrap.sh ]
then
    # make sure that bootstrap.sh is executable
    chmod +x bootstrap.sh
    # run the script
    ./bootstrap.sh
else
    echo 'ERROR: No bootstrap.sh found'
    exit 1
fi

# vim: ts=4 ts=4 sts=4 et :
