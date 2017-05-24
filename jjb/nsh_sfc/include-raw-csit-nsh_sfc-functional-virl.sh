#!/bin/bash

# execute nsh_sfc bootstrap script if it exists
if [ -e bootstrap-nsh_sfc-functional-virl.sh ]
then
    # make sure that bootstrap-nsh_sfc-functional-virl.sh is executable
    chmod +x bootstrap-nsh_sfc-functional-virl.sh
    # run the script
    ./bootstrap-nsh_sfc-functional-virl.sh
else
    echo 'ERROR: No bootstrap-nsh_sfc-functional-virl.sh found'
    exit 1
fi

# vim: ts=4 ts=4 sts=4 et :
