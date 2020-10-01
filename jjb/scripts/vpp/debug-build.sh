#!/bin/bash
echo "---> debug-build.sh"

set -xe -o pipefail

OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_ARCH=$(uname -m)

echo "BUILD OS: ${OS_ID}-${OS_VERSION_ID} ($OS_ARCH)"

# TODO: fix this to print nomad server hostname
# do nothing but print the current slave hostname
hostname

echo "sha1sum of this script: ${0}"
sha1sum $0

# run with ASAN on
# export VPP_EXTRA_CMAKE_ARGS='-DVPP_ENABLE_SANITIZE_ADDR=ON'

# clang is not working with ASAN right now - see change 27268
# apparently gcc neither...
# export CC=gcc

make UNATTENDED=yes install-dep
make UNATTENDED=yes install-ext-deps
make UNATTENDED=yes build
make UNATTENDED=yes TEST_JOBS=auto test-debug

echo "*******************************************************************"
echo "* VPP debug/asan test BUILD on ${OS_ID^^}-${OS_VERSION_ID}-${OS_ARCH^^} SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
