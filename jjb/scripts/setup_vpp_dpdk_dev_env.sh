#!/bin/bash
set -e -o pipefail

OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')

function setup {
    if ! [ -z ${REPO_NAME} ]; then
        echo "INSTALLING VPP-DPKG-DEV from apt/yum repo"
        REPO_URL="${NEXUSPROXY}/content/repositories/fd.io.${REPO_NAME}"
        echo "REPO_URL: ${REPO_URL}"
        # Setup by installing vpp-dev and vpp-lib
        if [ "$DISTRIB_ID" == "ubuntu" ]; then
            echo "deb ${REPO_URL} ./" | sudo tee /etc/apt/sources.list.d/99fd.io.list
            sudo apt-get update || true
            sudo apt-get -y --force-yes install vpp-dpdk-dev || true
            sudo apt-get -y --force-yes install vpp-dpdk-dkms || true
        elif [ "$DISTRIB_ID" == "centos" ]; then
            sudo cat << EOF > fdio-master.repo
[fdio-master]
name=fd.io master branch latest merge
baseurl=${REPO_URL}
enabled=1
gpgcheck=0
EOF
            sudo mv fdio-master.repo /etc/yum.repos.d/fdio-master.repo
            sudo yum -y install vpp-dpdk-devel || true
        fi
    fi
}

setup
