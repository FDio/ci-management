#!/bin/bash -ex

export CCACHE_DIR=/tmp/ccache

fetch_ccache

# building core

cd linux_dpdk
./b configure
./b build
cd -

cd linux
./b configure
./b build
cd -

# building docs
# Commented out to trex-docs is integrated into trex repo

#cd trex-doc
#./b configure
#./b build
#cd -

push_ccache

echo "*******************************************************************"
echo "* TREX BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"

