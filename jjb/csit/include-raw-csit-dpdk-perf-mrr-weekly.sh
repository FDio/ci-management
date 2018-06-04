#!/bin/bash
set -xeu -o pipefail

# check BRANCH_ID value
if [ "$BRANCH_ID" == "" ]; then
    echo "branch_id not provided => 'master' will be used"
    BRANCH_ID="master"
fi

# make sure there is no csit directory
if [ -d "./csit/" ]; then
    rm -rf ./csit/
fi

# clone csit
git clone --depth 1 --no-single-branch https://gerrit.fd.io/r/csit

# if the git clone fails, complain clearly and exit
if [ $? != 0 ]; then
    echo "Failed to run: git clone --depth 1 --no-single-branch https://gerrit.fd.io/r/csit"
    exit 1
fi

cd csit

# get the latest verified version of the required branch
BRANCH_NAME=$(echo $(git branch -r | grep -E "${BRANCH_ID}-[0-9]+" | tail -n 1))

if [ "${BRANCH_NAME}" == "" ]; then
    echo "No verified version found for requested branch - exiting"
    exit 1
fi

# remove 'origin/' from the branch name
BRANCH_NAME=$(echo ${BRANCH_NAME#origin/})

# checkout to the required branch
git checkout ${BRANCH_NAME}

export TEST_TAG="PERFTEST_MRR_DAILY"

# execute csit bootstrap script if it exists
if [ -e bootstrap-verify-perf-DPDK.sh ]
then
    # make sure that bootstrap.sh is executable
    chmod +x bootstrap-verify-perf-DPDK.sh
    # run the script
    ./bootstrap-verify-perf-DPDK.sh
else
    echo 'ERROR: No bootstrap-verify-perf-DPDK.sh found'
    exit 1
fi

# vim: ts=4 ts=4 sts=4 et :
