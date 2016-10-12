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

MISSING_PKGS=$(dpkg-checkbuilddeps |& perl -pe 's/^.+://g; s/\(.*?\)//g')

sudo apt-get install -y ${MISSING_PKGS} devscripts pristine-tar

pkg_version=$(dpkg-parsechangelog --show-field Version)
orig_version=$(echo ${pkg_version} | sed s'/-.*//')
orig_tarball="dpdk_${orig_version}.orig.tar.gz"
pristine-tar checkout ${orig_tarball}
mv ${orig_tarball} ..

debuild -uc -us -j4

# No fail on lintian errors
set +e
lintian --info --no-tag-display-limit "dpdk_${pkg_version}_source.changes"

echo "*******************************************************************"
echo "* DEB_DPDK BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
