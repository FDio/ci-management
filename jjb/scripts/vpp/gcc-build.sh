#!/bin/bash
# basic build script example
set -xe -o pipefail

OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')

echo OS_ID: $OS_ID
echo OS_VERSION_ID: $OS_VERSION_ID

# do nothing but print the current slave hostname
hostname

echo "cat /etc/bootstrap.sha"
if [ -f /etc/bootstrap.sha ];then
    cat /etc/bootstrap.sha
else
    echo "Cannot find cat /etc/bootstrap.sha"
fi

echo "cat /etc/bootstrap-functions.sha"
if [ -f /etc/bootstrap-functions.sha ];then
    cat /etc/bootstrap-functions.sha
else
    echo "Cannot find cat /etc/bootstrap-functions.sha"
fi

echo "sha1sum of this script: ${0}"
sha1sum $0
export CC=gcc

make UNATTENDED=yes install-dep
make UNATTENDED=yes install-ext-deps
make UNATTENDED=yes build
# TODO: Add 'smoke test' env var to select smoke test cases
#       then update this accordingly.  For now pick a few basic suites...
MAKE_TEST_SUITES="vlib vppinfra vpe_api vapi vom bihash"
for suite in $MAKE_TEST_SUITES ; do
    make UNATTENDED=yes GCOV_TESTS=1 TEST_JOBS=auto TEST=$suite test
    make UNATTENDED=yes GCOV_TESTS=1 TEST_JOBS=auto TEST=$suite test-debug
done

echo "*******************************************************************"
echo "* VPP GCC BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
