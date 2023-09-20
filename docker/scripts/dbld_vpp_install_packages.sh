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
. "$CIMAN_DOCKER_SCRIPTS/lib_vpp.sh"
. "$CIMAN_DOCKER_SCRIPTS/lib_apt.sh"

must_be_run_in_docker_build

echo_log
if ! vpp_supported_executor_class "$FDIOTOOLS_EXECUTOR_CLASS" ; then
    echo_log "VPP is not supported on executor class '$FDIOTOOLS_EXECUTOR_CLASS'. Skipping $(basename $0)..."
    exit 0
else
    echo_log "Starting  $(basename $0)"
fi

do_git_config vpp
for branch in ${VPP_BRANCHES[$OS_NAME]} ; do
    do_git_branch "$branch"

    # Install OS packages
    make_vpp "install-dep" "$branch"
    if [ "$OS_ID" = "ubuntu" ] && [ "$OS_ARCH" = "x86_64" ] ; then
        # 'Make docs jobs are only run on ubuntu x86_64 executors
        #  so only run for ubuntu build executors.
        make_vpp "docs-venv" "$branch"
    fi

    # Download, build, and cache external deps packages
    make_vpp "install-ext-deps" "$branch"
    vpp_ext_dir="$DOCKER_VPP_DIR/build/external"
    rsync -ac $vpp_ext_dir/downloads/. $DOCKER_DOWNLOADS_DIR || true
    if which apt >/dev/null ; then
        vpp_ext_deps_pkg=$vpp_ext_dir/$(dpkg -l vpp-ext-deps 2>/dev/null | mawk '/vpp-ext-deps/{print $2"_"$3"_"$4".deb"}')
    else
        echo "ERROR: Package Manager not installed!"
        exit 1
    fi
    if [ -f "$vpp_ext_deps_pkg" ] ; then
        cp -f $vpp_ext_deps_pkg $DOCKER_DOWNLOADS_DIR
    else
        echo "ERROR: Missing VPP external deps package: '$vpp_ext_deps_pkg'"
        exit 1
    fi
    # Install/cache python packages
    make_vpp_test "test-dep" "$branch"
    if [ "$OS_ID" = "ubuntu" ] ; then
        make_vpp test-wipe "$branch"
    fi
    # Clean up virtual environment
    git checkout -q -- .
    git clean -qfdx

    # Dump packages installed
    case "$DOCKERFILE_FROM" in
        *ubuntu*)
            dump_apt_package_list "$branch" ;;
        *debian*)
            dump_apt_package_list "$branch" ;;
    esac
done

echo_log -e "Completed $(basename $0)!\n\n=========="
