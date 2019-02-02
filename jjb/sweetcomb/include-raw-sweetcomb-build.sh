#!/bin/bash
# basic build script example
set -xe -o pipefail

OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')

echo OS_ID: $OS_ID
echo OS_VERSION_ID: $OS_VERSION_ID

echo "Building using \"make build-root/build.sh\""
[ "x${DRYRUN}" == "xTrue" ] || make UNATTENDED=yes install-dep
[ "x${DRYRUN}" == "xTrue" ] || make UNATTENDED=yes install-dep-extra
[ "x${DRYRUN}" == "xTrue" ] || make UNATTENDED=yes install-vpp
[ "x${DRYRUN}" == "xTrue" ] || make UNATTENDED=yes build-scvpp
[ "x${DRYRUN}" == "xTrue" ] || make UNATTENDED=yes build

echo "*******************************************************************"
echo "* SWEETCOMB BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
