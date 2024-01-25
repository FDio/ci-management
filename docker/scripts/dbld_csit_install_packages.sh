#! /bin/bash

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

set -euxo pipefail

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. "$CIMAN_DOCKER_SCRIPTS/lib_csit.sh"
. "$CIMAN_DOCKER_SCRIPTS/lib_vpp.sh"

must_be_run_in_docker_build

echo_log

if ! csit_supported_executor_class "$FDIOTOOLS_EXECUTOR_CLASS" ; then
    echo_log "CSIT is not supported on executor class '$FDIOTOOLS_EXECUTOR_CLASS'. Skipping $(basename $0)..."
    exit 0
elif ! csit_supported_os "$OS_NAME" ; then
    echo_log "CSIT is not supported on OS '$OS_NAME'. Skipping $(basename $0)..."
    exit 0
else
    echo_log "Starting  $(basename $0)"
fi

do_git_config csit
for vpp_branch in ${VPP_BRANCHES[$OS_NAME]} ; do
    # Returns checked out branch in csit_branch
    csit_checkout_branch_for_vpp "$vpp_branch"

    # Install csit OS packages
    csit_install_packages "$csit_branch"

    # Install/cache python packages
    csit_install_hugo "$csit_branch"

    # Install/cache python packages
    if grep -q 'PyYAML==5.4.1' "$DOCKER_CSIT_DIR/requirements.txt" ; then
        to_be_deprecated_csit_pip_cache "$csit_branch"
    else
        csit_pip_cache "$csit_branch"
    fi
done

echo_log -e "Completed $(basename $0)!\n\n=========="
