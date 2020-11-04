#!/bin/bash

# Copyright (c) 2020 Cisco and/or its affiliates.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

echo "---> jjb/scripts/setup_vpp_dpdk_dev_env.sh"

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
        if [ "${OS_ID,,}" == "ubuntu" ] || [ "${OS_ID,,}" == "debian" ] ; then
            if [ "${STREAM}" != "master" ]; then
                echo "stream '${STREAM}' is not master: replacing packagecloud apt sources list with stream specific list"
                sudo apt-get -y remove vpp-ext-deps || true
                sudo rm -f /etc/apt/sources.list.d/fdio_master.list
                curl -s $INSTALL_URL/script.deb.sh | sudo bash
            fi
            sudo apt-get update -qq || true
            vpp_ext_deps_version="$(apt-cache show vpp-ext-deps | mawk '/Version/ {print $2}' | head -1)"
            vpp_ext_deps_arch="$(apt-cache show vpp-ext-deps | mawk '/Architecture/ {print $2}' | head -1)"
            vpp_ext_deps_pkg="/root/Downloads/vpp-ext-deps_${vpp_ext_deps_version}_${vpp_ext_deps_arch}.deb"
            if [ -f "$vpp_ext_deps_pkg" ] ; then
                echo "Installing cached vpp-ext-deps pkg: $vpp_ext_deps_pkg"
                sudo dpkg -i $vpp_ext_deps_pkg
            else
                echo "Installing vpp-ext-deps from packagecloud.io"
                local force_opts="--allow-downgrades --allow-remove-essential"
                force_opts="$force_opts --allow-change-held-packages"
                sudo apt-get -y $force_opts install vpp-ext-deps || true
            fi
        elif [ "${OS_ID,,}" == "centos" ] ; then
            if [ "${STREAM}" != "master" ] ; then
                echo "stream '${STREAM}' is not master: replacing packagecloud repo list with stream specific list"
                sudo rm -f /etc/yum.repos.d/fdio_master.repo
                curl -s $INSTALL_URL/script.rpm.sh | sudo bash
            fi
            sudo yum -y install vpp-ext-deps || true
        else
            echo "ERROR: Unsupported OS '$OS_ID'!"
        fi
    else
        echo "ERROR: REPO_NAME not found!"
    fi
}

setup
