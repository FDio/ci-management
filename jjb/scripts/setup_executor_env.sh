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

echo "---> jjb/scripts/setup_executor_env.sh"

set -e -o pipefail

OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_ARCH=$(uname -m)
dockerfile="/scratch/docker-build/Dockerfile"
file_delimiter="----- %< -----"
long_line="************************************************************************"
downloads_cache="/root/Downloads"

echo "$long_line"
echo "Executor OS: $OS_ID-$OS_VERSION_ID"
echo "Executor Arch: $OS_ARCH"
# TODO: fix this to print nomad server hostname
echo "Executor hostname: $(hostname)"

echo "$long_line"
if [ -f "$dockerfile" ] ; then
    echo -e "Executor Dockerfile: ${dockerfile}\n${file_delimiter}"
    cat $dockerfile
    echo "$file_delimiter"
else
    echo "Unknown Executor: '$dockerfile' not found!"
fi

echo "$long_line"
echo "Executor package list:"
if [ "$OS_ID" == "ubuntu" ] || [ "$OS_ID" = "debian" ] ; then
    dpkg-query -W -f='${binary:Package}\t${Version}\n' | column -t || true
elif [ "$OS_ID" == "centos" ] ; then
    yum list installed || true
fi

echo "$long_line"
echo "Python3 package list:"
pip3 list 2>/dev/null | column -t || true

echo "$long_line"
echo "Executor Downloads cache '$downloads_cache':"
ls -lh "$downloads_cache" || true
echo "$long_line"
echo "DNS nameserver config in '/etc/resolv.conf':"
cat /etc/resolv.conf || true

if [ -n "${CCACHE_DIR:-}" ] ; then
    echo "$long_line"
    if [ -d "$CCACHE_DIR" ] ; then
        num_ccache_files="$(find $CCACHE_DIR -type f | wc -l)"
        echo "CCACHE_DIR='$CCACHE_DIR' ($num_ccache_files ccache files):"
        du -sh /tmp/ccache
        df -h /tmp/ccache
        ls -l $CCACHE_DIR
        unset -v CCACHE_DISABLE
    else
        echo "CCACHE_DIR='$CCACHE_DIR' is missing, disabling CCACHE..."
        unset -v CCACHE_DIR
        export CCACHE_DISABLE="1"
    fi
fi
echo "$long_line"
