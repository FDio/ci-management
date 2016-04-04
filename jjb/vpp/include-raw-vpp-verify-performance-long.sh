#!/bin/bash
set -xeu -o pipefail

export TEST_TAG='PERFTEST_LONG'

# Clone csit and start tests
git clone --depth 1 https://gerrit.fd.io/r/csit --branch csit-verified

cp build-root/*.deb csit/
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
