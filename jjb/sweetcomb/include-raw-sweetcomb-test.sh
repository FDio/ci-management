#!/bin/bash
# basic build script example
set -xe -o pipefail

##container server node detection
grep search /etc/resolv.conf  || true

OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')

echo OS_ID: $OS_ID
echo OS_VERSION_ID: $OS_VERSION_ID

echo "Building using \"make build-root/build.sh\""
[ "x${DRYRUN}" == "xTrue" ] || make UNATTENDED=yes install-test-extra
[ "x${DRYRUN}" == "xTrue" ] || make build-scvpp
[ "x${DRYRUN}" == "xTrue" ] || make build-plugins
[ "x${DRYRUN}" == "xTrue" ] || useradd user
[ "x${DRYRUN}" == "xTrue" ] || bash -c "echo -e \"user\nuser\" | passwd user"
[ "x${DRYRUN}" == "xTrue" ] || make UNATTENDED=yes test-plugins

echo "*******************************************************************"
echo "* SWEETCOMB TEST SUCCESSFULLY COMPLETED"
echo "*******************************************************************"

