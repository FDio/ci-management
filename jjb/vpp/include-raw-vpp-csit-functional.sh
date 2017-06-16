#!/bin/bash
set -xeu -o pipefail

# Get CSIT branch from which to test from
# running build-root/scripts/csit-test-branch
if [ -x build-root/scripts/csit-test-branch ]; then
    CSIT_BRANCH=`build-root/scripts/csit-test-branch`;
fi

# Clone csit and start tests
git clone https://gerrit.fd.io/r/csit --branch ${CSIT_BRANCH:-csit-verified}

# If the git clone fails, complain clearly and exit
if [ $? != 0 ]; then
    echo "Failed to run: git clone https://gerrit.fd.io/r/csit --branch ${CSIT_BRANCH:-csit-verified}"
    echo "No such branch ${CSIT_BRANCH:-csit-verified} in https://gerrit.fd.io/r/csit"
    exit
fi

cp build-root/*.deb csit/
if [ -e dpdk/vpp-dpdk-dkms*.deb ]
then
    cp dpdk/vpp-dpdk-dkms*.deb csit/
else
    cp /var/cache/apt/archives/vpp-dpdk-dkms*.deb csit/
fi

cd csit
# execute csit bootstrap script if it exists
if [ -e bootstrap.sh ]
then
    # make sure that bootstrap.sh is executable
    chmod +x bootstrap.sh
    # run the script
    ./bootstrap.sh *.deb
else
    echo 'ERROR: No bootstrap.sh found'
    exit 1
fi

# vim: ts=4 ts=4 sts=4 et :
