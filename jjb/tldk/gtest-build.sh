#!/bin/bash
# basic build script example
set -e -o pipefail
set -x
echo $WORKSPACE
git clone https://github.com/google/googletest.git $WORKSPACE/googletest
cmake $WORKSPACE/googletest/CMakeLists.txt
echo GTEST_DIR=$WORKSPACE/googletest/googletest > gtest-env.prop
echo GMOCK_DIR=$WORKSPACE/googletest/googlemock >> gtest-env.prop

echo "*******************************************************************"
echo "* GTEST BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
