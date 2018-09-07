#!/bin/bash
# basic build script example
set -e -o pipefail

# Make DMM
./scripts/build.sh all

echo "*******************************************************************"
echo "* DMM BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"

# Run unit tests application
#need to be added

#echo "*******************************************************************"
#echo "* DMM UNIT TESTS SUCCESSFUL"
#echo "*******************************************************************"
