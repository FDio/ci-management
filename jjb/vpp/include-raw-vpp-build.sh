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

if [ ${OS} == "ubuntu1404" ] || [ ${OS} == "ubuntu1604" ]; then
    cd build-root/
    ./bootstrap.sh
    make PLATFORM=vpp V=0 TAG=vpp install-deb
elif [ ${OS} == "centos7" ]; then
    cd build-root/
    ./bootstrap.sh
    make PLATFORM=vpp V=0 TAG=vpp install-rpm
else
    echo "Unrecognized OS: ${OS}.  Please edit: https://gerrit.fd.io/r/gitweb?p=ci-management.git;a=blob;f=jjb/vpp/include-raw-vpp-build.sh;h=f3cb320bd9a2515eab0c4564c927764c9dad417d;hb=HEAD"
    exit 1
fi