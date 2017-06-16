#!/bin/bash
set -xeu -o pipefail

TRIGGER=`echo ${GERRIT_EVENT_COMMENT_TEXT} \
    | grep -oE 'vpp-verify-perf-(l2|ip4|ip6|lisp|vxlan|vhost)' \
    | awk '{print toupper($0)}'`
export TEST_TAG=${TRIGGER}

# Get CSIT branch from which to test from
# running build-root/scripts/csit-test-branch
if [ -x build-root/scripts/csit-test-branch ]; then
    CSIT_BRANCH=`build-root/scripts/csit-test-branch`;
fi

# Clone csit and start tests
git clone --depth 1 https://gerrit.fd.io/r/csit --branch ${CSIT_BRANCH:-csit-verified}

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
if [ ! -e bootstrap-verify-perf.sh ]
then
    echo 'ERROR: No bootstrap-verify-perf.sh found'
    exit 1
fi

# make sure that bootstrap-verify-perf.sh is executable
chmod +x bootstrap-verify-perf.sh
# run the script
./bootstrap-verify-perf.sh *.deb

# vim: ts=4 ts=4 sts=4 et :
