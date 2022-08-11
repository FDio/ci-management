#!/bin/bash

# Copyright (c) 2022 Cisco and/or its affiliates.
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

echo "---> jjb/scripts/setup_vpp_ext_deps.sh"

# Normally we would have the settings in any bash script stricter:
#    set -e -o pipefail
#
# But there is a corner case scenario that triggers an error,
# namely when a new packagecloud repo is created, it is completely
# empty. Then the installation fails. However, since this
# script is an optimization, it is okay for it to fail without failing
# the entire job.
#
# Therefore, we do not use the "-e" here.

set -o pipefail

OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')

echo "Installing vpp-ext-deps..."
REPO_URL="https://packagecloud.io/fdio/${STREAM}"
echo "REPO_URL: $REPO_URL"
INSTALL_URL="https://packagecloud.io/install/repositories/fdio/${STREAM}"
echo "INSTALL_URL: $INSTALL_URL"

downloads_dir="/root/Downloads"

# Setup by installing vpp-dev and vpp-lib
if [ "${OS_ID,,}" == "ubuntu" ] || [ "${OS_ID,,}" == "debian" ] ; then
    if [ "${STREAM}" != "master" ]; then
        echo "stream '${STREAM}' is not master: replacing packagecloud apt sources list with stream specific list"
        sudo apt-get -y remove vpp-ext-deps || true
        sudo rm -f /etc/apt/sources.list.d/fdio_master.list
        curl -s $INSTALL_URL/script.deb.sh | sudo bash || true
    fi
    sudo apt-get update -qq || true
    vpp_ext_deps_version="$(apt-cache show vpp-ext-deps | mawk '/Version/ {print $2}' | head -1)"
    vpp_ext_deps_arch="$(apt-cache show vpp-ext-deps | mawk '/Architecture/ {print $2}' | head -1)"
    vpp_ext_deps_pkg="vpp-ext-deps_${vpp_ext_deps_version}_${vpp_ext_deps_arch}.deb"
    if [ -f "$downloads_dir/$vpp_ext_deps_pkg" ] ; then
        echo "Installing cached vpp-ext-deps pkg: $downloads_dir/$vpp_ext_deps_pkg"
        sudo dpkg -i "$downloads_dir/$vpp_ext_deps_pkg" || true
    else
        echo "Installing vpp-ext-deps from packagecloud.io"
        force_opts="--allow-downgrades --allow-remove-essential --allow-change-held-packages"
        sudo apt-get -y $force_opts install vpp-ext-deps || true
    fi
    echo "Removing packagecloud.io repository references and running apt-get update"
    sudo rm -f /etc/apt/sources.list.d/fdio_*.list
    sudo apt-get update -qq || true
else
    echo "ERROR: Unsupported OS '$OS_ID'!"
fi
