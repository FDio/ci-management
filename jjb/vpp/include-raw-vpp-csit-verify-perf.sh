#!/bin/bash

set -xeu -o pipefail

if [[ ${GERRIT_EVENT_TYPE} == 'comment-added' ]]; then
    TRIGGER=`echo ${GERRIT_EVENT_COMMENT_TEXT} \
        | grep -oE '(perftest$|perftest[[:space:]].+$)'`
else
    TRIGGER=''
fi
# Export test type.
export TEST_TAG="VERIFY-PERF-PATCH"
# Export test tags as string.
export TEST_TAG_STRING=${TRIGGER#$"perftest"}

# Get CSIT branch from which to test from
# running build-root/scripts/csit-test-branch
if [ -x build-root/scripts/csit-test-branch ]; then
    CSIT_BRANCH=`build-root/scripts/csit-test-branch`;
fi

# check CSIT_BRANCH value
if [ "$CSIT_BRANCH" == "" ]; then
    echo "CSIT_BRANCH not provided => 'latest' will be used"
    CSIT_BRANCH="latest"
fi

# clone csit
git clone --depth 1 --no-single-branch https://gerrit.fd.io/r/csit

# if the git clone fails, complain clearly and exit
if [ $? != 0 ]; then
    echo "Failed to run: git clone --depth 1 --no-single-branch https://gerrit.fd.io/r/csit"
    exit 1
fi

cp build-root/*.deb csit/
if [ -e dpdk/vpp-dpdk-dkms*.deb ]
then
    cp dpdk/vpp-dpdk-dkms*.deb csit/
else
    cp /w/dpdk/vpp-dpdk-dkms*.deb csit/ 2>/dev/null || :
    cp /var/cache/apt/archives/vpp-dpdk-dkms*.deb csit/ 2>/dev/null || :
fi

cd csit
# If also testing a specific csit refpoint look for CSIT_REF
if [[ -v CSIT_REF ]]; then
    git fetch ssh://rotterdam-jobbuilder@gerrit.fd.io:29418/csit $CSIT_REF && git checkout FETCH_HEAD
else
    if [ "$CSIT_BRANCH" == "latest" ]; then
        # set required CSIT branch_id based on VPP master branch; by default use 'oper'
        case "$VPP_BRANCH" in
            master )
                BRANCH_ID="oper"
                ;;
            stable/1710 )
                BRANCH_ID="oper-rls1710"
                ;;
            stable/1801 )
                BRANCH_ID="oper-rls1801"
                ;;
            * )
                BRANCH_ID="oper"
        esac

        # get the latest verified version of the required branch
        CSIT_BRANCH=$(echo $(git branch -r | grep -E "${BRANCH_ID}-[0-9]+" | tail -n 1))

        if [ "${CSIT_BRANCH}" == "" ]; then
            echo "No verified CSIT branch found - exiting"
            exit 1
        fi

        # remove 'origin/' from the branch name
        CSIT_BRANCH=$(echo ${CSIT_BRANCH#origin/})
    fi

    # checkout the required csit branch
    git checkout ${CSIT_BRANCH}

    if [ $? != 0 ]; then
        echo "Failed to checkout the required CSIT branch: ${CSIT_BRANCH}"
        exit 1
    fi
fi

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
