#!/bin/bash
# basic build script example

# do nothing but print the current slave hostname
hostname
cd build-root/
./bootstrap.sh
make PLATFORM=vpp TAG=vpp_debug install-vpp
