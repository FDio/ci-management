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
        sudo apt-get install -y fonts-font-awesome fonts-lato libjs-modernizr
        local NEX_PFX=https://nexus.fd.io/content/repositories/thirdparty/sphinx/rtd/theme
        local VER=0.1.9-1.1_all
        local URLS=""
        local FILES=""
        for PKG in sphinx-rtd-theme-common python-sphinx-rtd-theme
        do
            URLS="${URLS} ${NEX_PFX}/${PKG}/${VER}/${PKG}-${VER}.deb"
            FILES="${FILES} /tmp/${PKG}-${VER}.deb"
        done
        wget -P /tmp ${URLS}
        sudo dpkg -i ${FILES}
    )
fi

MISSING_PKGS=$(dpkg-checkbuilddeps |& perl -pe 's/^.+://g; s/\(.*?\)//g')
sudo apt-get install -y ${MISSING_PKGS}

debuild -uc -us -j4

echo "*******************************************************************"
echo "* DEB_DPDK BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
