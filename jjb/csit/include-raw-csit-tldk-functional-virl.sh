#!/bin/bash
set -xeu -o pipefail

# execute tldk bootstrap script if it exists
if [ -e bootstrap-TLDK.sh ]
then
    # make sure that bootstrap-TLDK.sh is executable
    chmod +x bootstrap-TLDK.sh
    # run the script
    ./bootstrap-TLDK.sh
else
    echo 'ERROR: No bootstrap-TLDK.sh found'
    exit 1
fi

# vim: ts=4 ts=4 sts=4 et :
