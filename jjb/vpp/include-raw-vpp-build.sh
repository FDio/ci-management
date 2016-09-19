#!/bin/bash
# basic build script example
set -xe -o pipefail
# do nothing but print the current slave hostname
hostname
export CCACHE_DIR=/tmp/ccache

fetch_cache

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
    sudo update-java-alternatives -s /usr/lib/jvm/java-1.7.0-openjdk-amd64 || echo 'ignoring failure'
fi

build-root/vagrant/build.sh

push_ccache

echo "*******************************************************************"
echo "* VPP BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
