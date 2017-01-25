#!/bin/bash
set -xeu -o pipefail

current_dir=`pwd`
cd ${WORKSPACE}

# Get CSIT branch from which to test from
# running build-root/scripts/csit-test-branch
if [ -x csit-test-branch ]; then
    CSIT_BRANCH=`csit-test-branch`;
fi

# Clone csit and start tests
git clone https://gerrit.fd.io/r/csit --branch ${CSIT_BRANCH}

# If the git clone fails, complain clearly and exit
if [ $? != 0 ]; then
    echo "Failed to run: git clone https://gerrit.fd.io/r/csit --branch ${CSIT_BRANCH}"
    exit
fi

./csit/resources/tools/download_hc_build_pkgs.sh ${STREAM}

cd ${current_dir}
