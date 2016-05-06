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

# Make sure we are starting on java-7.  This catches bugs in the
# vpp build system that can occur on Ubuntu 14.04 when a user may
# have both java-7 and java-8 installed.
if [ ${OS} == ubuntu1404 ];then
    sudo update-java-alternatives -s /usr/lib/jvm/java-1.7.0-openjdk-amd64
fi

build-root/vagrant/build.sh
