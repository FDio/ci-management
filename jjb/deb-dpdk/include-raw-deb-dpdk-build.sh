#!/bin/bash

echo "*******************************************************************"
echo "* DEB-DPDK BUILD STARTED"
echo "*******************************************************************"

set -xe -o pipefail

echo "*******************************************************************"
echo "* INSTALL BUILD DEPENDENCIES"
echo "*******************************************************************"

sudo /usr/lib/pbuilder/pbuilder-satisfydepends

echo "*******************************************************************"
echo "* PERFORM UNSIGNED BUILD"
echo "*******************************************************************"

export DEB_BUILD_OPTIONS="parallel=8 nocheck"

# On home system with 12 cores and ram-based disk: 8m03.911s
# On home system with 02 cores and RAID-5 disks:   8m36.966s

date
time debuild -uc -us
date


echo "*******************************************************************"
echo "* VERIFY OUTPUT MANIFEST"
echo "*******************************************************************"

echo "TODO"

echo "*******************************************************************"
echo "* DEB-DPDK BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
