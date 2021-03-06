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
. "$CIMAN_DOCKER_SCRIPTS/lib_yum.sh"
. "$CIMAN_DOCKER_SCRIPTS/lib_dnf.sh"

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
    make_vpp "centos-pyyaml" "$branch" # VPP Makefile tests for centos versions
    if [ "$OS_ID" = "ubuntu" ] ; then
        # 'Make docs jobs are only run on ubuntu executors
        #  so only run for ubuntu build executors.
        make_vpp "docs-venv" "$branch"
    elif [ "$OS_NAME" = "debian-9" ] ; then
        apt_override_cmake_install_with_pip3_version
    fi

    # Download, build, and cache external deps packages
    make_vpp "install-ext-deps" "$branch"
    vpp_ext_dir="$DOCKER_VPP_DIR/build/external"
    rsync -ac $vpp_ext_dir/downloads/. $DOCKER_DOWNLOADS_DIR || true
    if which apt >/dev/null ; then
        vpp_ext_deps_pkg=$vpp_ext_dir/$(dpkg -l vpp-ext-deps 2>/dev/null | mawk '/vpp-ext-deps/{print $2"_"$3"_"$4".deb"}')
    elif which dnf >/dev/null ; then
        inst_vpp_ext_deps="$(dnf list vpp-ext-deps 2>/dev/null | grep vpp-ext-deps)"
        vpp_ext_deps_ver="$(echo $inst_vpp_ext_deps | mawk '{print $2}')"
        vpp_ext_deps_arch="$(echo $inst_vpp_ext_deps | mawk '{print $1}'| cut -d'.' -f2)"
        vpp_ext_deps_pkg="$vpp_ext_dir/vpp-ext-deps-${vpp_ext_deps_ver}.${vpp_ext_deps_arch}.rpm"
    elif which yum >/dev/null ; then
        inst_vpp_ext_deps="$(yum list vpp-ext-deps 2>/dev/null | grep vpp-ext-deps)"
        vpp_ext_deps_ver="$(echo $inst_vpp_ext_deps | mawk '{print $2}')"
        vpp_ext_deps_arch="$(echo $inst_vpp_ext_deps | mawk '{print $1}' | cut -d'.' -f2)"
        vpp_ext_deps_pkg="$vpp_ext_dir/vpp-ext-deps-${vpp_ext_deps_ver}.${vpp_ext_deps_arch}.rpm"
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
    if [ "$OS_ID" = "ubuntu" ] ; then
        make_vpp_test "test-dep" "$branch"
        make_vpp_test "doc" "$branch"
        make_vpp test-wipe "$branch"
        make_vpp "bootstrap-doxygen" "$branch"
    fi

    # Dump packages installed
    case "$DOCKERFILE_FROM" in
        *ubuntu*)
            dump_apt_package_list "$branch" ;;
        *debian*)
            dump_apt_package_list "$branch" ;;
        *centos:7)
            dump_yum_package_list "$branch" ;;
        *centos:8)
            dump_dnf_package_list "$branch" ;;
    esac
done

echo_log -e "Completed $(basename $0)!\n\n=========="
