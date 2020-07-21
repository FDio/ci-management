#! /bin/bash

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

set -euxo pipefail

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. $CIMAN_DOCKER_SCRIPTS/lib_csit.sh
. $CIMAN_DOCKER_SCRIPTS/lib_vpp.sh

must_be_run_as_root
must_be_run_in_docker_build

case "$OS_NAME" in
    ubuntu-18.04)
        supported_os="true" ;;
    *)
        supported_os="" ;;
esac
if [ -z "$supported_os" ] ; then
    echo "CSIT is not supported on $OS_NAME. Skipping CSIT package install..."
    exit 0
fi

echo_log
echo_log "Starting  $(basename $0)"

do_git_config csit
for vpp_branch in ${VPP_BRANCHES[$OS_NAME]} ; do
    # Returns checked out branch in csit_branch
    csit_checkout_branch_for_vpp $vpp_branch

    # Install csit OS packages
    csit_install_packages $csit_branch

    # Install/cache python packages
    csit_pip_cache $csit_branch
done

echo_log -e "Completed $(basename $0)!\n\n=========="
