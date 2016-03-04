#!/bin/bash

# execute csit bootstrap script if it exists
if [ -e bootstrap-multilink.sh ]
then
    # make sure that bootstrap.sh is executable
    chmod +x bootstrap-multilink.sh
    # run the script
    ./bootstrap-multilink.sh
else
    echo 'ERROR: No bootstrap-multilink.sh found'
    exit 1
fi

# vim: ts=4 ts=4 sts=4 et :
