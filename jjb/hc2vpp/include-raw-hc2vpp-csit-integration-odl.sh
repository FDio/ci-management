#!/bin/bash
set -xeu -o pipefail

# Get CSIT branch
if [ -f csit-test-branch ]; then
    chmod +x csit-test-branch
    CSIT_BRANCH=`./csit-test-branch`
else
    CSIT_BRANCH='master'
fi

# Clone csit
git clone https://gerrit.fd.io/r/csit --branch ${CSIT_BRANCH}

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
    if [ ${STREAM} == 'master' ]; then
        ./bootstrap-hc2vpp-integration-odl.sh ${STREAM} ${OS} ${ODL}
    else
        ./bootstrap-hc2vpp-integration-odl.sh 'stable.'${STREAM} ${OS} ${ODL}
    fi
fi

# vim: ts=4 ts=4 sts=4 et :
