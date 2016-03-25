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
cd build-root/
./bootstrap.sh
make PLATFORM=vpp_lite TAG=vpp_lite install-packages
make PLATFORM=vpp V=0 TAG=vpp install-deb
