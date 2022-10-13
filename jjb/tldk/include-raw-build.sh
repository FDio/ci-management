#!/bin/bash
# basic build script example
set -e -o pipefail
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
    echo "Cannot find /etc/bootstrap.sha"
fi

echo "cat /etc/bootstrap-functions.sha"
if [ -f /etc/bootstrap-functions.sha ];then
    cat /etc/bootstrap-functions.sha
else
    echo "Cannot find /etc/bootstrap-functions.sha"
fi

# Make TLDK
make

echo "*******************************************************************"
echo "* TLDK BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"

# Run unit tests application
sudo $WORKSPACE/x86_64-native-linuxapp-gcc/app/gtest-rfc --lcores=0 -n 2

echo "*******************************************************************"
echo "* TLDK UNIT TESTS SUCCESSFUL"
echo "*******************************************************************"

if [ -f "$WORKSPACE/examples/l4fwd/test/run_test.sh" ]
then
	export ETH_DEV="tap"
	export L4FWD_PATH=$WORKSPACE/x86_64-native-linuxapp-gcc/app/l4fwd
	export L4FWD_FECORE=0
	export L4FWD_BECORE=1

	sudo -E /bin/bash $WORKSPACE/examples/l4fwd/test/run_test.sh -46a

	echo "*****************************************************************"
	echo "* TLDK OFO/LOST SEGMENT TESTS SUCCESSFUL"
	echo "*****************************************************************"
fi
