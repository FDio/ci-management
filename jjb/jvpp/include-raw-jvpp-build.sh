#!/bin/bash
# basic build script example
set -xe -o pipefail

OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')

echo OS_ID: ${OS_ID}
echo OS_VERSION_ID: ${OS_VERSION_ID}

# do nothing but print the current slave hostname
hostname
export CCACHE_DIR=/tmp/ccache
if [[ -d ${CCACHE_DIR} ]];then
    echo ${CCACHE_DIR} exists
    du -sk ${CCACHE_DIR}
else
    echo ${CCACHE_DIR} does not exist.  This must be a new slave.
fi

echo "cat /etc/bootstrap.sha"
if [[ -f /etc/bootstrap.sha ]];then
    cat /etc/bootstrap.sha
else
    echo "Cannot find cat /etc/bootstrap.sha"
fi

echo "cat /etc/bootstrap-functions.sha"
if [[ -f /etc/bootstrap-functions.sha ]];then
    cat /etc/bootstrap-functions.sha
else
    echo "Cannot find cat /etc/bootstrap-functions.sha"
fi

echo "sha1sum of this script: ${0}"
sha1sum $0

echo "CC=${CC}"

echo "Building using \"make package\""
# ensure that we build from scratch
./clean.sh
[[ "x${DRYRUN}" == "xTrue" ]] || cd Requirements && make UNATTENDED=yes install-dep && cd ..
#[[ "x${DRYRUN}" == "xTrue" ]] || make rebuild_cache
[[ "x${DRYRUN}" == "xTrue" ]] || make package
# This will build deb or rpm JVPP package based on OS. Built packages are located in build-root/packages/

echo "*******************************************************************"
echo "* JVPP BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
