#!/bin/bash

# basic build script example
DEBUG=1
set -e -o pipefail

SCRIPTDIR=$(realpath "$(dirname $0)/../../")
[ "${DEBUG}" -gt "0" ] && source "${SCRIPTDIR}/scripts/debug.sh"

make

echo "*******************************************************************"
echo "* TLDK BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
