#!/bin/bash
# basic build script example
set -e -o pipefail
set -x
echo $WORKSPACE
git clone https://github.com/google/googletest.git $WORKSPACE/googletest
cmake $WORKSPACE/googletest/CMakeLists.txt

echo "*******************************************************************"
echo "* GTEST BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
