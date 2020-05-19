#!/bin/bash
# basic build script example
set -xe -o pipefail

##container server node detection
grep search /etc/resolv.conf  || true

OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')

echo OS_ID: $OS_ID
echo OS_VERSION_ID: $OS_VERSION_ID

echo "Building using \"make deb-${MODE} openssl3_enable=1 vpp=${STREAM}\""

make deb-${MODE} openssl3_enable=1 vpp=${STREAM}
make verify-${MODE} openssl3_enable=1

echo "*******************************************************************"
echo "* VSAP ${MODE} ${STREAM} BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
