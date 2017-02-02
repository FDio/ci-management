#!/bin/bash
set -xeu -o pipefail

current_dir=`pwd`
cd ${WORKSPACE}

# Get CSIT branch from which to test from
# running build-root/scripts/csit-test-branch
if [ -f csit-test-branch ]; then
    chmod +x csit-test-branch
    CSIT_BRANCH=`./csit-test-branch`
fi

# Clone csit and start tests
git clone https://gerrit.fd.io/r/csit --branch ${CSIT_BRANCH}

# If the git clone fails, complain clearly and exit
if [ $? != 0 ]; then
    echo "Failed to run: git clone https://gerrit.fd.io/r/csit --branch ${CSIT_BRANCH}"
    exit
fi

if [ ${STREAM} == 'master' ]; then
    ./csit/resources/tools/download_hc_build_pkgs.sh ${STREAM}
else
    ./csit/resources/tools/download_hc_build_pkgs.sh 'stable.'${STREAM}
fi

cd ${current_dir}
