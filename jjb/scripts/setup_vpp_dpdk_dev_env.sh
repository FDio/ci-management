#!/bin/bash
echo "---> setup_vpp_dpdk_dev_env.sh"

set -e -o pipefail

OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')

function setup {
    if [ -n "$REPO_NAME" ] ; then
        echo "Installing vpp-ext-deps..."
        REPO_URL="https://packagecloud.io/fdio/${STREAM}"
        echo "REPO_URL: $REPO_URL"
        INSTALL_URL="https://packagecloud.io/install/repositories/fdio/${STREAM}"
        echo "INSTALL_URL: $INSTALL_URL"
        # Setup by installing vpp-dev and vpp-lib
        if [ "$OS_ID" == "ubuntu" ]; then
            if [ "${STREAM}" != "master" ]; then
                echo "stream '${STREAM}' is not master: replacing packagecloud apt sources list with stream specific list"
                sudo rm  -f /etc/apt/sources.list.d/fdio_master.list
                curl -s $INSTALL_URL/script.deb.sh | sudo bash
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
            if [ "${STREAM}" != "master" ]; then
                echo "stream '${STREAM}' is not master: replacing packagecloud repo list with stream specific list"
                sudo rm -f /etc/yum.repos.d/fdio_master.repo
                curl -s $INSTALL_URL/script.rpm.sh | sudo bash
            fi
            sudo yum -y install vpp-ext-deps || true
        fi
    else
        echo "ERROR: REPO_NAME not found!"
    fi
}

setup
