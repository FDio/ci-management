#!/bin/bash
set -xeu -o pipefail

# get branch_id value from command line options
if [ "${#}" -ne "0" ]; then
    while [ "${#}" -ne "0" ]; do
         case $1 in
             -B | --branch_id )     shift
                                    BRANCH_ID=$1
         esac
         shift
    done
else
    echo "branch_id not provided => 'master' will be used"
    BRANCH_ID="master"
fi

# clone csit
git clone --depth 1 --no-single-branch https://gerrit.fd.io/r/csit

# if the git clone fails, complain clearly and exit
if [ $? != 0 ]; then
    echo "Failed to run: git clone --depth 1 --no-single-branch https://gerrit.fd.io/r/csit"
    exit 1
fi

cd csit

# get list of all branches available on the remote
BRANCH_ARR=($(git branch -r))

# find the latest verified version of the required branch
BRANCH_NAME=""
for index in "${!BRANCH_ARR[@]}"; do
    if [[ ${BRANCH_ARR[${index}]} == origin/csit-verified-${BRANCH_ID}-* ]]; then
        if [[ "${BRANCH_ARR[${index}]}" > "${BRANCH_NAME}" ]]; then
            BRANCH_NAME="${BRANCH_ARR[${index}]}"
        fi
    fi
done

# remove 'origin/' from the branch name
BRANCH_NAME=$(echo ${BRANCH_NAME#origin/})

# checkout to the required branch
git checkout ${BRANCH_NAME}

# execute csit bootstrap script if it exists
if [ -e bootstrap-vpp-verify-semiweekly.sh ]
then
    # make sure that bootstrap.sh is executable
    chmod +x bootstrap-vpp-verify-semiweekly.sh
    # run the script
    ./bootstrap-vpp-verify-semiweekly.sh
else
    echo 'ERROR: No bootstrap-vpp-verify-semiweekly.sh found'
    exit 1
fi

# vim: ts=4 ts=4 sts=4 et :
