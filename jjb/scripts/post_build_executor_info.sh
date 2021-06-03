#!/bin/bash

# Copyright (c) 2021 Cisco and/or its affiliates.
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

echo "---> jjb/scripts/post_build_executor_info.sh"

# Output executor runtime attributes [again] in case the job fails prior to
# running setup_executor_env.sh
long_line="************************************************************************"
OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_ARCH=$(uname -m)
echo "$long_line"
echo "Executor Runtime Attributes:"
echo "OS: $OS_ID-$OS_VERSION_ID"
echo "    $(uname -a)"
echo "Number CPUs: $(nproc)"
echo "Arch: $OS_ARCH"
echo "Nomad Hostname: $(grep search /etc/resolv.conf | cut -d' ' -f2 | head -1)"
echo "Container ID: $(hostname)"
echo "$long_line"
echo -e "lscpu:\n$(lscpu)"
echo "$long_line"
echo -e "df -h:\n$(df -h)"
echo "$long_line"
echo -e "free -m:\n$(free -m)"

if [ -n "$(which ccache)" ] ; then
    echo "$long_line"
    echo "ccache statistics:"
    [ -n "${CCACHE_DISABLE:-}" ] && echo "CCACHE_DISABLE = '$CCACHE_DISABLE'"
    [ -n "${CCACHE_DIR:-}" ] && echo "CCACHE_DIR = '$CCACHE_DIR'"
    ccache -s
fi

echo "$long_line"

# Avoid sar anomaly on centos-7 in global-jjb/shell/logs-deploy.sh
#
# Note: VPP 20.09 will be removed in the next release cycle (21.10),
#       therefore this hack is better than polluting the docker image
#       build scripts with code to avoid installing sysstat on centos-7.
#
# TODO: Remove when vpp-*-2009-centos7-x86_64 jobs are removed
if [ "$OS_ID" = "centos" ] && [ "$OS_VERSION_ID" = "7"  ] ; then
    sudo yum remove -y sysstat >& /dev/null || true
fi
