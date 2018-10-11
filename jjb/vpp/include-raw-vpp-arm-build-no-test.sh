#!/bin/bash
# basic build script example
set -xe -o pipefail

OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')

echo OS_ID: $OS_ID
echo OS_VERSION_ID: $OS_VERSION_ID

# do nothing but print the current slave hostname
hostname
export CCACHE_DIR=/tmp/ccache
if [ -d $CCACHE_DIR ];then
    echo $CCACHE_DIR exists
    du -sk $CCACHE_DIR
else
    echo $CCACHE_DIR does not exist.  This must be a new slave.
fi

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

echo "CC=${CC}"

make UNATTENDED=yes install-dep
make UNATTENDED=yes dpdk-install-dev
make UNATTENDED=yes -C build-root PLATFORM=vpp TAG=vpp wipe-all install-packages
make UNATTENDED=yes -C build-root PLATFORM=vpp TAG=vpp sample-plugin-install
make UNATTENDED=yes -C build-root PLATFORM=vpp TAG=vpp libmemif-install
make UNATTENDED=yes pkg-deb

if [ "x${VPP_REPO}" == "x1" ]; then
    if [ "x${REBASE_NEEDED}" == "x1" ]; then
        echo "This patch to vpp is based on an old point in the tree that is likely"
        echo "to fail verify."
        echo "PLEASE REBASE PATCH ON THE CURRENT HEAD OF THE VPP REPO"
        exit 1
    fi
fi

echo "*******************************************************************"
echo "* VPP ARM BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
