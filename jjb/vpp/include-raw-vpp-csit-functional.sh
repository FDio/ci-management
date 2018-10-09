#!/bin/bash
set -xeu -o pipefail

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
    cp /w/dpdk/vpp-dpdk-dkms*.deb csit/
fi

# Check for CSIT_REF test file
if [ -e CSIT_REF ]; then
    source CSIT_REF
fi

# If also testing a specific csit refpoint look for CSIT_REF
if [[ -v CSIT_REF ]]; then
    (cd csit ; git fetch ssh://rotterdam-jobbuilder@gerrit.fd.io:29418/csit $CSIT_REF && git checkout FETCH_HEAD)
else
    cd csit
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
            stable/1804 )
                BRANCH_ID="oper-rls1804"
                ;;
            stable/1807 )
                BRANCH_ID="oper-rls1807"
                ;;
            stable/1810 )
                BRANCH_ID="oper-rls1810"
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
if [ -e bootstrap.sh ]
then
    # make sure that bootstrap.sh is executable
    chmod +x bootstrap.sh
    # run the script
    ./bootstrap.sh *.deb
else
    echo 'ERROR: No bootstrap.sh found'
    exit 1
fi

# vim: ts=4 ts=4 sts=4 et :
