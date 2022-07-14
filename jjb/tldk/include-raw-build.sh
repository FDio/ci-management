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

echo "sha1sum of this script: ${0}"
sha1sum $0

# depending on the branch being targetted, the build system may be meson + ninja
# or may be make
if [ "${env.GERRIT_BRANCH}" = "dev-mitm-proxy" ]; then
  # this block is meson + ninja
  # Make TLDK
  meson build
  ninja -C build

  echo "*******************************************************************"
  echo "* TLDK BUILD SUCCESSFULLY COMPLETED"
  echo "*******************************************************************"

  # Run unit tests application
  sudo $WORKSPACE/build/app/test/tldk-test --lcores=0 -n 2

  echo "*******************************************************************"
  echo "* TLDK UNIT TESTS SUCCESSFUL"
  echo "*******************************************************************"

  if [ -f "$WORKSPACE/examples/l4fwd/test/run_test.sh" ]
  then
    export ETH_DEV="tap"
    export L4FWD_PATH=$WORKSPACE/build/examples/l4fwd/tldk-l4fwd
    export L4FWD_FECORE=0
    export L4FWD_BECORE=1

    sudo -E /bin/bash $WORKSPACE/examples/l4fwd/test/run_test.sh -46a

    echo "*****************************************************************"
    echo "* TLDK OFO/LOST SEGMENT TESTS SUCCESSFUL"
    echo "*****************************************************************"
  fi

else
  # this block is make files
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
fi
