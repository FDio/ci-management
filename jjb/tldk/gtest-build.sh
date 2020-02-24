#!/bin/bash
set -e -o pipefail
echo $WORKSPACE
git clone -v https://github.com/google/googletest.git --branch release-1.10.0 \
$WORKSPACE/googletest
cmake $WORKSPACE/googletest/CMakeLists.txt
make -C $WORKSPACE/googletest
echo GTEST_DIR=$WORKSPACE/googletest/googletest > gtest-env.prop
echo GMOCK_DIR=$WORKSPACE/googletest/googlemock >> gtest-env.prop

echo "*******************************************************************"
echo "* GTEST BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"

