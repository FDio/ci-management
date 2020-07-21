#!/bin/bash
set -e -o pipefail

OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')

function setup {
    if ! [ -z ${REPO_NAME} ]; then
        echo "Installing vpp-ext-deps..."
        REPO_URL="https://packagecloud.io/fdio/${STREAM}"
        echo "REPO_URL: ${REPO_URL}"
        # Setup by installing vpp-dev and vpp-lib
        if [ "$OS_ID" == "ubuntu" ]; then
            if [ "${STREAM}" != "master" ]; then
                echo "{stream} is not master: deleting packagecloud apt sources list"
                sudo rm  -f /etc/apt/sources.list.d/fdio_master.list
                curl -s https://packagecloud.io/install/repositories/fdio/${STREAM}/script.deb.sh | sudo bash
            fi
            sudo apt-get update -qq || true
            curr_vpp_ext_deps="/root/Downloads/$(basename $(apt-cache show vpp-ext-deps | grep Filename | head -1 | cut -d' ' -f2))"
            if [ -f "$curr_vpp_ext_deps" ] ; then
                echo "Installing cached vpp-ext-deps pkg: $curr_vpp_ext_deps"
                sudo dpkg -i $curr_vpp_ext_deps
            else
                echo "Installing vpp-ext-deps from packagecloud.io"
                local force_opts="--allow-downgrades --allow-remove-essential"
                force_opts="$force_opts --allow-change-held-packages"
                sudo apt-get -y $force_opts install vpp-ext-deps || true
            fi
        elif [ "$OS_ID" == "centos" ]; then
            if [ -f /etc/yum.repos.d/fdio-master.repo ]; then
                echo "Deleting: /etc/yum.repos.d/fdio-master.repo"
                sudo rm /etc/yum.repos.d/fdio-master.repo
            fi
            if [ "${STREAM}" != "master" ]; then
                echo "tree not master deleting packagecloud repo pointer"
                sudo rm  -f /etc/yum.repos.d/fdio_master.repo
                curl -s https://packagecloud.io/install/repositories/fdio/${STREAM}/script.rpm.sh | sudo bash
            fi
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
            sudo yum -y install vpp-ext-deps || true
        fi
    fi
}

setup
