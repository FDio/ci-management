#!/bin/bash
# basic build script example

# do nothing but print the current slave hostname
hostname
export CCACHE_DIR=/tmp/ccache
if [ -d $CCACHE_DIR ];then
    echo $CCACHE_DIR exists
    du -sk $CCACHE_DIR
else
    echo $CCACHE_DIR does not exist.  This must be a new slave.
fi

# Check to make sure the patch doesn't need to be rebased
# Since there was a discontinuity, patches with a
# parent before 30d41ff need to be rebased

(git log --oneline | grep 30d41ff > /dev/null 2>&1);if [ $? != 0 ]; then REBASE_NEEDED="1";fi
(git log --oneline | grep fb0815d > /dev/null 2>&1);if [ $? == 0 ]; then VPP_REPO="1";fi
echo "REBASE_NEEDED: ${REBASE_NEEDED}"
echo "VPP_REPO: ${VPP_REPO}"

if [ "x${VPP_REPO}" == "x1" ]; then
    if [ "x${REBASE_NEEDED}" == "x1" ]; then
        echo "This patch to vpp is based on an old point in the tree that is likely"
        echo "to fail verify."
        echo "PLEASE REBASE PATCH ON THE CURRENT HEAD OF THE VPP REPO"
        exit 1
    fi
fi

# Make sure we are starting on java-7.  This catches bugs in the
# vpp build system that can occur on Ubuntu 14.04 when a user may
# have both java-7 and java-8 installed.
if [ ${OS} == ubuntu1404 ];then
    sudo update-java-alternatives -s /usr/lib/jvm/java-1.7.0-openjdk-amd64
fi

build-root/vagrant/build.sh
if [ $? == 0 ];then
    echo "*******************************************************************"
    echo "* VPP BUILD SUCCESSFULLY COMPLETED"
    echo "*******************************************************************"
fi