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

echo "cat /etc/bootstrap.sha1"
if [ -f /etc/bootstrap.sh1 ];then
    cat /etc/bootstrap.sha1
else
    echo "Cannot find cat /etc/bootstrap.sha1"
fi

echo "shasum of this script"
shasum $0

build-root/vagrant/build.sh
