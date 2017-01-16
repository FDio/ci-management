#!/bin/bash
set -e -o pipefail
echo $WORKSPACE
git clone https://github.com/google/googletest.git $WORKSPACE/googletest
cmake $WORKSPACE/googletest/CMakeLists.txt
make -C $WORKSPACE/googletest
echo GTEST_DIR=$WORKSPACE/googletest/googletest > gtest-env.prop
echo GMOCK_DIR=$WORKSPACE/googletest/googlemock >> gtest-env.prop

echo "*******************************************************************"
echo "* GTEST BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"

