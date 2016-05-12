#!/bin/bash
set -xeu -o pipefail

# Clone csit and start tests
git clone https://gerrit.fd.io/r/csit --branch master

cd csit

# execute csit bootstrap script if it exists
if [ -e bootstrap-vpp-verify-weekly.sh ]
then
    # make sure that bootstrap.sh is executable
    chmod +x bootstrap-vpp-verify-weekly.sh
    # run the script
    ./bootstrap-vpp-verify-weekly.sh
else
    echo 'ERROR: No bootstrap-verify-master.sh found'
    exit 1
fi

# vim: ts=4 ts=4 sts=4 et :
