#!/bin/bash
# basic build script example
set -xe -o pipefail
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

# Due to a shift to make verify, after 2016-12-01 we need to make sure any patches
# coming in happen after 37682e1
(git log --oneline | grep 37682e1 > /dev/null 2>&1) || \
    (echo "PLEASE REBASE PATCH ON THE CURRENT HEAD OF THE VPP REPO"; exit 1)

echo "CC=${CC}"
make UNATTENDED=yes verify

echo "*******************************************************************"
echo "* VPP BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
