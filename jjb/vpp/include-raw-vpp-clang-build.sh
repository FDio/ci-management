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

make UNATTENDED=yes CC=clang CXX=clang install-dep
make UNATTENDED=yes CC=clang CXX=clang dpdk-install-dev
make UNATTENDED=yes -C build-root PLATFORM=vpp TAG=vpp_clang CC=clang install-packages
make UNATTENDED=yes -C build-root PLATFORM=vpp TAG=vpp_clang CC=clang CXX=clang sample-plugin-install
make UNATTENDED=yes -C build-root PLATFORM=vpp TAG=vpp libmemif-install


echo "*******************************************************************"
echo "* VPP CLANG BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
