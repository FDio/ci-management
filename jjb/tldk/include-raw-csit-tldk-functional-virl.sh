#!/bin/bash
set -xeu -o pipefail

# Clone tldk and start tests
git clone https://gerrit.fd.io/r/tldk

# Clone csit and start tests
git clone https://gerrit.fd.io/r/csit

# If the git clone fails, complain clearly and exit
if [ $? != 0 ]; then
    echo "Failed to run: git clone https://gerrit.fd.io/r/csit"
exit
fi

cd csit

# execute nsh_sfc bootstrap script if it exists
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
