#!/bin/bash

set -xeu -o pipefail

# Clone csit and start tests
git clone https://gerrit.fd.io/r/csit

# If the git clone fails, complain clearly and exit
if [ $? != 0 ]; then
    echo "Failed to run: git clone https://gerrit.fd.io/r/csit"
    exit 1
fi

cd csit

# execute  nsh_sfc bootstrap script if it exists
if [ ! -e bootstrap-verify-perf-nsh_sfc.sh ]
then
    echo 'ERROR: No bootstrap-verify-perf-nsh_sfc.sh found'
    exit 1
fi

# make sure that bootstrap-verify-perf.sh is executable
chmod +x bootstrap-verify-perf-nsh_sfc.sh
# run the script
./bootstrap-verify-perf-nsh_sfc.sh

# vim: ts=4 ts=4 sts=4 et :
