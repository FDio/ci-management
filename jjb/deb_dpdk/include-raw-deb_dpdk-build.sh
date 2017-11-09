#!/bin/bash

set -e -o pipefail

# print the current slave hostname
hostname

for hashfile in bootstrap.sha bootstrap-functions.sha
do
    echo -n "${hashfile}: "
    if [ -f /etc/${hashfile} ];then
        cat /etc/${hashfile}
    else
        echo "Cannot find ${hashfile}"
    fi
done

echo "sha1sum of script [${0}]: " $(sha1sum $0)

MISSING_PKGS=$(dpkg-checkbuilddeps |& perl -pe 's/^.+://g; s/\(.*?\)//g; s/\|\s+\S+//g;')
MISSING_PKGS="devscripts pristine-tar ${MISSING_PKGS}"

if [ -n "${MISSING_PKGS}" ]
then
    echo "*******************************************************************"
    echo "* ADD MISSING DEPENDENCIES TO RESPIN SCRIPT:"
    echo "${MISSING_PKGS}"
    echo "*******************************************************************"
fi

sudo apt-get update
sudo apt-get install -y ${MISSING_PKGS}

pkg_version=$(dpkg-parsechangelog --show-field Version)
orig_version=$(echo ${pkg_version} | perl -pe 's/-.+$//') # remove debian suffix
orig_tarball=$(git ls-tree remotes/origin/pristine-tar | perl -ne "print /(dpdk_${orig_version}.orig.+).id/")

pristine-tar checkout ${orig_tarball}
mv ${orig_tarball} ..

debuild -uc -us -j4

# No fail on lintian errors
set +e
lintian --info --no-tag-display-limit "dpdk_${pkg_version}_source.changes"

echo "*******************************************************************"
echo "* DEB_DPDK BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
