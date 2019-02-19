#!/bin/bash
# basic build script example
set -xe -o pipefail

##container server node detection
grep search /etc/resolv.conf  || true

OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')

echo OS_ID: $OS_ID
echo OS_VERSION_ID: $OS_VERSION_ID

function setup {
    if ! [ -z ${REPO_NAME} ]; then
        echo "INSTALLING VPP-DPKG-DEV from apt/yum repo"
        REPO_URL="https://packagecloud.io/fdio/${STREAM}"
        echo "REPO_URL: ${REPO_URL}"
        # Setup by installing vpp-dev and vpp-lib
        if [ "$OS_ID" == "ubuntu" ]; then
            if [ -f /etc/apt/sources.list.d/99fd.io.list ];then
                echo "Deleting: /etc/apt/sources.list.d/99fd.io.list"
                sudo rm /etc/apt/sources.list.d/99fd.io.list
            fi
            curl -s https://packagecloud.io/install/repositories/fdio/${STREAM}/script.deb.sh | sudo bash
        elif [ "$OS_ID" == "centos" ]; then
            if [ -f /etc/yum.repos.d/fdio-master.repo ]; then
                echo "Deleting: /etc/yum.repos.d/fdio-master.repo"
                sudo rm /etc/yum.repos.d/fdio-master.repo
            fi
            curl -s https://packagecloud.io/install/repositories/fdio/${STREAM}/script.rpm.sh | sudo bash
        fi
    fi
}

setup

echo "Building using \"make build-root/build.sh\""
[ "x${DRYRUN}" == "xTrue" ] || make UNATTENDED=yes install-dep
[ "x${DRYRUN}" == "xTrue" ] || make UNATTENDED=yes install-dep-extra
[ "x${DRYRUN}" == "xTrue" ] || make UNATTENDED=yes install-vpp
[ "x${DRYRUN}" == "xTrue" ] || make UNATTENDED=yes build-package

echo "*******************************************************************"
echo "* SWEETCOMB BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
