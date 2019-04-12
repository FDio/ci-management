#!/bin/bash
set -e -o pipefail

OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')

function setup {
    if ! [ -z ${REPO_NAME} ]; then
        echo "INSTALLING VPP-DPKG-DEV from apt/yum repo"
        REPO_URL="https://packagecloud.io/fdio/${STREAM}"
        echo "REPO_URL: ${REPO_URL}"
        # Setup by installing vpp-dev and vpp-lib
        if [ "$OS_ID" == "ubuntu" ]; then
            apt_source_list_dir="/etc/apt/sources.list.d"
            for source_list in $(ls -1 $apt_source_list_dir | grep fdio) ; do
                if [ -f "$apt_source_list_dir/$source_list" ] ; then
                    echo "Deleting: $apt_source_list_dir/$source_list"
                    sudo rm $apt_source_list_dir/$source_list
                fi
            done
            if [ -f "$apt_source_list_dir/99fd.io.list" ];then
                echo "Deleting: $apt_source_list_dir/99fd.io.list"
                sudo rm $apt_source_list_dir/99fd.io.list
            fi
            curl -s https://packagecloud.io/install/repositories/fdio/${STREAM}/script.deb.sh | sudo bash
            sudo apt-get -y --force-yes install vpp-dpdk-dev || true
            sudo apt-get -y --force-yes install vpp-dpdk-dkms || true
            sudo apt-get -y --force-yes install vpp-ext-deps || true
        elif [ "$OS_ID" == "centos" ]; then
            if [ -f /etc/yum.repos.d/fdio-master.repo ]; then
                echo "Deleting: /etc/yum.repos.d/fdio-master.repo"
                sudo rm /etc/yum.repos.d/fdio-master.repo
            fi
            curl -s https://packagecloud.io/install/repositories/fdio/${STREAM}/script.rpm.sh | sudo bash
            sudo yum -y install vpp-dpdk-devel || true
            sudo yum -y install vpp-ext-deps || true
        elif [ "$OS_ID" == "opensuse" ]; then
            REPO_URL="${NEXUSPROXY}/content/repositories/fd.io.${REPO_NAME}"
            echo "REPO_URL: ${REPO_URL}"
            sudo cat << EOF > fdio-master.repo
[fdio-master]
name=fd.io master branch latest merge
baseurl=${REPO_URL}
enabled=1
gpgcheck=0
EOF
            sudo mv fdio-master.repo /etc/yum/repos.d/fdio-master.repo
            sudo yum -y install vpp-dpdk-devel || true
            sudo yum -y install vpp-ext-deps || true
        elif [ "$OS_ID" == "opensuse-leap" ]; then
            REPO_URL="${NEXUSPROXY}/content/repositories/fd.io.${REPO_NAME}"
            echo "REPO_URL: ${REPO_URL}"
            sudo cat << EOF > fdio-master.repo
[fdio-master]
name=fd.io master branch latest merge
baseurl=${REPO_URL}
enabled=1
gpgcheck=0
EOF
            sudo mv fdio-master.repo /etc/yum/repos.d/fdio-master.repo
            sudo yum -y install vpp-dpdk-devel || true
            sudo yum -y install vpp-ext-deps || true
        fi
    fi
}

setup
