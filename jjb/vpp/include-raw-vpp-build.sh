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

echo "CC=${CC}"
echo "IS_CSIT_VPP_JOB=${IS_CSIT_VPP_JOB}"

# If and only if we are doing verify *after* make verify was made to work
# and we are not a CSIT job just building packages, then use make verify,
# else use the old build-root/vagrant/build.sh
if (git log --oneline | grep 37682e1 > /dev/null 2>&1) && \
        [ "x${IS_CSIT_VPP_JOB}" != "xTrue" ]
then
    echo "Building using \"make verify\""
    [ "x${DRYRUN}" != "True" ]|| make UNATTENDED=yes verify
else
    echo "Building using \"build-root/vagrant/build.sh\""
    [ "x${DRYRUN}" != "True" ] || build-root/vagrant/build.sh
fi


echo "*******************************************************************"
echo "* VPP BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
