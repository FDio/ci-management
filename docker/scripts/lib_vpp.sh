# lib_vpp.sh - Docker build script VPP library.
#              For import only.

# Copyright (c) 2024 Cisco and/or its affiliates.
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

# Don't import more than once.
if [ -n "$(alias lib_vpp_imported 2> /dev/null)" ] ; then
    return 0
fi
alias lib_vpp_imported=true

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname "${BASH_SOURCE[0]}")"}
. "$CIMAN_DOCKER_SCRIPTS"/lib_common.sh


VPP_SUPPORTED_EXECUTOR_CLASSES="builder"
vpp_supported_executor_class() {
    if ! grep -q "${1:-}" <<< "$VPP_SUPPORTED_EXECUTOR_CLASSES"; then
        return 1
    fi
    return 0
}

install_hst_deps() {
    local branch=${1:-"master"}
    local branchname=${branch/\//_}
    local hst_dir="./extras/hs-test"
    local bld_log="$DOCKER_BUILD_LOG_DIR"
    bld_log="${bld_log}/$FDIOTOOLS_IMAGENAME-$branchname"
    bld_log="${bld_log}-install_hst_deps_bld.log"

    if [ -d "$hst_dir" ] ; then
        make -C "$hst_dir" install-deps 2>&1 | tee -a "$bld_log"
    fi
}

make_vpp() {
    local target=$1
    local branch=${2:-"master"}
    local clean=${3:-"true"}
    local branchname=${branch/\//_}
    local bld_log="$DOCKER_BUILD_LOG_DIR"
    if [ "$target" = "install-ext-deps" ] ; then
        if [ -d "$DOCKER_VPP_DL_CACHE_DIR" ] ; then
            mkdir -p "$DOCKER_DOWNLOADS_DIR"
            cp -a "$DOCKER_VPP_DL_CACHE_DIR"/* "$DOCKER_DOWNLOADS_DIR"
        fi
    fi
    bld_log="${bld_log}/$FDIOTOOLS_IMAGENAME-$branchname"
    bld_log="${bld_log}-make_vpp_${target}-bld.log"

    makefile_target="^${target}:"
    if ! grep "$makefile_target" Makefile ; then
        echo "Make target '$target' does not exist in VPP branch '$branch'!"
        return
    fi
    if [ "$clean" = "true" ] ; then
        git clean -qfdx
    fi
    description="'make UNATTENDED=yes $target' in $(pwd) ($branch)"
    echo_log -e "    Starting  $description..."
    make UNATTENDED=yes "$target" 2>&1 | tee -a "$bld_log"
    git checkout -q -- .
    echo_log "    Completed $description!"
}

make_vpp_test() {
    local target=$1
    local branch=${2:-"master"}
    local branchname=${branch/\//_}
    local bld_log="$DOCKER_BUILD_LOG_DIR"
    bld_log="${bld_log}/$FDIOTOOLS_IMAGENAME-$branchname"
    bld_log="${bld_log}-make_vpp_test_${target}-bld.log"

    makefile_target="^${target}:"
    if ! grep -e "$makefile_target" test/Makefile ; then
        echo "Make test target '$target' does not exist in VPP branch '$branch'!"
        return
    fi
    git clean -qfdx
    description="'make -C test $target' in $(pwd) ($branch)"
    echo_log "    Starting  $description..."
    make WS_ROOT="$DOCKER_VPP_DIR" BR="$DOCKER_VPP_DIR/build-root" \
         TEST_DIR="$DOCKER_VPP_DIR"/test -C test "$target" 2>&1 | tee -a "$bld_log"
    remove_pyc_files_and_pycache_dirs
    git checkout -q -- .
    echo_log "    Completed $description!"
}

docker_build_setup_vpp() {
    if vpp_supported_executor_class "$EXECUTOR_CLASS" ; then
        if [ ! -d "$DOCKER_VPP_DIR" ] ; then
            echo_log "Cloning VPP into $DOCKER_VPP_DIR..."
            git clone -q https://gerrit.fd.io/r/vpp $DOCKER_VPP_DIR
            if [ -d "$DOCKER_DOWNLOADS_DIR" ] ; then
                mkdir -p "$DOCKER_VPP_DL_CACHE_DIR"
                cp -a "$DOCKER_DOWNLOADS_DIR"/* "$DOCKER_VPP_DL_CACHE_DIR"
            fi
        fi
        clean_git_repo $DOCKER_VPP_DIR
    fi
}

# Branches must be listed in chronological order -- oldest stable branch
# first and master last.
#
# Note: CI Jobs for each architecture are maintained in
#       .../ci-management/jjb/vpp/vpp.yaml
#       All OS's and branches are included in the 'os' and 'stream'
#       definitions respectively, then the exclude list maintained
#       to create an enumerated set of jobs jobs that match the
#       definitions here.
declare -A VPP_BRANCHES
VPP_BRANCHES["debian-12"]="stable/2502 stable/2506 master"
VPP_BRANCHES["ubuntu-22.04"]="stable/2502 stable/2506 master"
VPP_BRANCHES["ubuntu-24.04"]="stable/2502 stable/2506 master"
export VPP_BRANCHES
