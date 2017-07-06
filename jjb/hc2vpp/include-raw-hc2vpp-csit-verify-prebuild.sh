#!/bin/bash
set -xeu -o pipefail

current_dir=`pwd`
cd ${WORKSPACE}

# Get CSIT branch from which to test from
# running build-root/scripts/csit-test-branch
if [ -f csit-test-branch ]; then
    chmod +x csit-test-branch
    CSIT_BRANCH=`./csit-test-branch`
else
    CSIT_BRANCH='master'
fi

# Clone csit and download VPP packages
git clone https://gerrit.fd.io/r/csit --branch ${CSIT_BRANCH}

# If the git clone fails, complain clearly and exit
if [ $? != 0 ]; then
    echo "Failed to run: git clone https://gerrit.fd.io/r/csit --branch ${CSIT_BRANCH}"
    exit
fi

cd csit

if [ ${STREAM} == 'master' ]; then
    ./resources/tools/scripts/download_hc_build_pkgs.sh ${STREAM} ${OS}
else
    ./resources/tools/scripts/download_hc_build_pkgs.sh 'stable.'${STREAM} ${OS}
fi

cd ${current_dir}
