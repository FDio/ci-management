#!/bin/bash
set -xeu -o pipefail

# execute csit bootstrap script if it exists
if [ -e bootstrap-vpp-verify-weekly.sh ]
then
    # make sure that bootstrap.sh is executable
    chmod +x bootstrap-vpp-verify-weekly.sh
    # run the script with branch as argument (use master by default)
    ./bootstrap-vpp-verify-weekly.sh ${GERRIT_BRANCH:-"master"}
else
    echo 'ERROR: No bootstrap-vpp-verify-weekly.sh found'
    exit 1
fi

# vim: ts=4 ts=4 sts=4 et :
