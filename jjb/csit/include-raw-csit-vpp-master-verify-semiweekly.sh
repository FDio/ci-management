#!/bin/bash
set -xeu -o pipefail

# Clone csit and start tests
git clone https://gerrit.fd.io/r/csit --branch csit-verified

cd csit

# execute csit bootstrap script if it exists
if [ -e bootstrap-vpp-master-verify-semiweekly.sh ]
then
    # make sure that bootstrap.sh is executable
    chmod +x bootstrap-vpp-master-verify-semiweekly.sh
    # run the script
    ./bootstrap-vpp-master-verify-semiweekly.sh
else
    echo 'ERROR: No bootstrap-verify-master.sh found'
    exit 1
fi

# vim: ts=4 ts=4 sts=4 et :
