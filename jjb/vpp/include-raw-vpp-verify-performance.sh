#!/bin/bash
set -xeu -o pipefail

# Clone csit and start tests
git clone https://gerrit.fd.io/r/csit --branch csit-verified

cp build-root/*.deb csit/
cd csit
# execute csit bootstrap script if it exists
if [ -e bootstrap-verify-perf.sh ]
then
    # make sure that bootstrap-verify-perf.sh is executable
    chmod +x bootstrap-verify-perf.sh
    # run the script
    ./bootstrap-verify-perf.sh *.deb
else
    echo 'ERROR: No bootstrap-verify-perf.sh found'
    exit 1
fi

# vim: ts=4 ts=4 sts=4 et :
