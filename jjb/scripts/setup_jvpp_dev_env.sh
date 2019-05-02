#!/bin/bash
set -e -o pipefail

# Figure out what system we are running on
if [[ -f /etc/lsb-release ]];then
    . /etc/lsb-release
elif [[ -f /etc/redhat-release ]];then
    sudo yum install -y redhat-lsb
    DISTRIB_ID=`lsb_release -si`
    DISTRIB_RELEASE=`lsb_release -sr`
    DISTRIB_CODENAME=`lsb_release -sc`
    DISTRIB_DESCRIPTION=`lsb_release -sd`
fi
echo DISTRIB_ID: $DISTRIB_ID
echo DISTRIB_RELEASE: $DISTRIB_RELEASE
echo DISTRIB_CODENAME: $DISTRIB_CODENAME
echo DISTRIB_DESCRIPTION: $DISTRIB_DESCRIPTION

JVPP_VERSION=`./version`
echo JVPP_VERSION: $JVPP_VERSION
# Check release version
if [[ "$JVPP_VERSION" == *"-release" ]]; then
    # at the time when JVPP release packages are being build,
    # vpp release packages are already promoted to release repository.
    # Therefore we need to switch to release repository in order to download
    # correct vpp package versions
    STREAM="release"
fi

function setup {
    if ! [[ -z ${REPO_NAME} ]]; then
        echo "INSTALLING VPP-DPKG-DEV from apt/yum repo"
        REPO_URL="https://packagecloud.io/fdio/${STREAM}"
        echo "REPO_URL: ${REPO_URL}"
        # Setup by installing vpp-dev and vpp-lib
        if [[ "$DISTRIB_ID" == "Ubuntu" ]]; then
            if ! [[ "${STREAM}" == "master" ]]; then
                echo "stable branch - clearing all fdio repos. new one will be installed."
                sudo rm  -f /etc/apt/sources.list.d/fdio_*.list
            fi
            if [[ -f /etc/apt/sources.list.d/99fd.io.list ]];then
                echo "Deleting: /etc/apt/sources.list.d/99fd.io.list"
                sudo rm /etc/apt/sources.list.d/99fd.io.list
            fi
            curl -s https://packagecloud.io/install/repositories/fdio/${STREAM}/script.deb.sh | sudo bash
            sudo apt-get -y --force-yes install libvppinfra libvppinfra-dev vpp vpp-dev vpp-plugin-core || true
        elif [[ "$DISTRIB_ID" == "CentOS" ]]; then
            if [[ -f /etc/yum.repos.d/fdio-master.repo ]]; then
                echo "Deleting: /etc/yum.repos.d/fdio-master.repo"
                sudo rm /etc/yum.repos.d/fdio-master.repo
            fi
            curl -s https://packagecloud.io/install/repositories/fdio/${STREAM}/script.rpm.sh | sudo bash
            sudo yum -y install vpp-devel vpp-lib vpp-plugins || true
        fi
    fi
}

setup