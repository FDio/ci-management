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
. $CIMAN_DOCKER_SCRIPTS/lib_vpp.sh
. $CIMAN_DOCKER_SCRIPTS/lib_apt.sh
. $CIMAN_DOCKER_SCRIPTS/lib_yum.sh
. $CIMAN_DOCKER_SCRIPTS/lib_dnf.sh

must_be_called_by_docker_build

echo_log
echo_log "Starting  $(basename $0)"

do_git_config vpp
for branch in ${VPP_BRANCHES[$OS_NAME]} ; do
  do_git_branch $branch

  # Install OS packages
  make_vpp "install-dep" $branch
  make_vpp "centos-pyyaml" $branch # VPP Makefile tests for centos versions
  if [ "$OS_ID" = "ubuntu" ] ; then
    # TODO: fix VPP stable/2005 bug in sphinx-make.sh
    #       which fails on 'yum install python3-venv'
    #       that does not exist.
    # 'Make docs jobs are only run on ubuntu executors
    #  so only run for ubuntu build executors until fixed.
    make_vpp "docs-venv" $branch
  fi

  # Download, build, and cache external deps packages
  make_vpp "install-ext-deps" $branch
  set +e
  vpp_ext_dir="$DOCKER_VPP_DIR/build/external"
  [ -d "$vpp_ext_dir/downloads" ] \
    && rsync -ac $vpp_ext_dir/downloads/. $DOCKER_DOWNLOADS_DIR
  [ -n "$(ls $vpp_ext_dir/*.deb)" ] \
    && rsync -ac $vpp_ext_dir/*.deb $DOCKER_DOWNLOADS_DIR
  [ -n "$(ls $vpp_ext_dir/*.rpm)" ] \
      && rsync -ac $vpp_ext_dir/*.rpm $DOCKER_DOWNLOADS_DIR
  set -e

  # Install/cache python packages
  if [ "$OS_ID" = "ubuntu" ] ; then
    make_vpp_test "test-dep" $branch
    make_vpp_test "doc" $branch
    make_vpp test-wipe $branch
    make_vpp "bootstrap-doxygen" $branch
  fi
  
  # Dump packages installed
  case "$DOCKERFILE_FROM" in
    *ubuntu*)
      dump_apt_package_list $branch
      ;;
    *debian*)
      dump_apt_package_list $branch
      ;;
    *centos:7)
      dump_yum_package_list $branch
      ;;
    *centos:8)
      dump_dnf_package_list $branch
      ;;
  esac
done

echo_log -e "Completed $(basename $0)!\n\n=========="
