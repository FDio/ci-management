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

SUPPORTED="ubuntu1404 ubuntu1604 centos7"
declare -A DIST_TARGET
DIST_TARGET=(
    [ubuntu1404]=install-deb
    [ubuntu1604]=install-deb
    [centos7]=install-rpm
)
if [[ ! ${SUPPORTED[*]} =~ ${OS} ]]
then
  echo "Unrecognized OS: ${OS}.  Please edit: https://gerrit.fd.io/r/gitweb?p=ci-management.git;a=blob;f=jjb/vpp/include-raw-vpp-build.sh;hb=HEAD"
    exit 1
fi
cd build-root/
./bootstrap.sh
make PLATFORM=vpp V=0 TAG=vpp ${DIST_TARGET[${OS}]}