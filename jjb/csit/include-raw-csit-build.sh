#!/bin/bash
# basic build script example

# do nothing but print the current slave hostname
git clone ssh://rotterdam-jobbuilder@gerrit.projectrotterdam.info:29418/vpp.git
cd vpp/build-root/
./bootstrap.sh
make PLATFORM=vpp TAG=vpp_debug install-deb
