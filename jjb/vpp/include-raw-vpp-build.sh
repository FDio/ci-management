#!/bin/bash
# basic build script example
set -xe -o pipefail
# do nothing but print the current slave hostname
hostname
export CCACHE_DIR=/tmp/ccache

fetch_ccache

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
    [ "x${DRYRUN}" == "xTrue" ] || make UNATTENDED=yes verify
else
    echo "Building using \"build-root/vagrant/build.sh\""
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

build-root/vagrant/build.sh

push_ccache

echo "*******************************************************************"
echo "* VPP BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
