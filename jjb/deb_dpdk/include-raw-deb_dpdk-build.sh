#!/bin/bash
# basic build script example
set -e -o pipefail
# do nothing but print the current slave hostname
hostname

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

if [ $OS == 'ubuntu1404' ]
then
    dpkg -l python-sphinx-rtd-theme | grep -q '^ii' || (
        echo "deb [trusted=yes] https://nexus.fd.io/content/repositories/thirdparty ./" > "/etc/apt/sources.list.d/FD.io.thirdparty.list"
        apt-get update
    )
fi

MISSING_PKGS=$(dpkg-checkbuilddeps |& perl -pe 's/^.+://g; s/\(.*?\)//g')
sudo apt-get install -y ${MISSING_PKGS}

debuild -uc -us -j4

echo "*******************************************************************"
echo "* DEB_DPDK BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
