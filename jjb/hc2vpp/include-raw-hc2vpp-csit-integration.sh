#!/bin/bash
set -xeu -o pipefail

# Clone csit and start tests
git clone https://gerrit.fd.io/r/csit --branch master

# If the git clone fails, complain clearly and exit
if [ $? != 0 ]; then
    echo "Failed to run: git clone https://gerrit.fd.io/r/csit --branch master"
    exit
fi

cd csit
# execute csit bootstrap script if it exists
if [ ! -e bootstrap-hc2vpp-integration.sh ]
then
    echo 'ERROR: No bootstrap-hc2vpp-integration.sh found'
    exit 1
else
    # make sure that bootstrap.sh is executable
    chmod +x bootstrap-hc2vpp-integration.sh
    # run the script
    ./bootstrap-hc2vpp-integration.sh
fi

# vim: ts=4 ts=4 sts=4 et :
