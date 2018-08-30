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
echo "IS_CSIT_VPP_JOB=${IS_CSIT_VPP_JOB}"
# If and only if we are doing verify *after* make verify was made to work
# and we are not a CSIT job just building packages, then use make verify,
# else use the old build-root/vagrant/build.sh
if (git log --oneline | grep 37682e1 > /dev/null 2>&1) && \
        [ "x${IS_CSIT_VPP_JOB}" != "xTrue" ]
then
    echo "Building using \"make verify\""
    [ "x${DRYRUN}" == "xTrue" ] || make TEST_JOBS=$TEST_JOBS UNATTENDED=yes verify
else
    echo "Building using \"make build-root/vagrant/build.sh\""
    [ "x${DRYRUN}" == "xTrue" ] || make UNATTENDED=yes install-dep
    [ "x${DRYRUN}" == "xTrue" ] || make UNATTENDED=yes dpdk-install-dev
    [ "x${DRYRUN}" == "xTrue" ] || build-root/vagrant/build.sh
fi

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
