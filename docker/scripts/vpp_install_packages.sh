#! /bin/bash

set -euxo pipefail

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. $CIMAN_DOCKER_SCRIPTS/lib_vpp.sh
. $CIMAN_DOCKER_SCRIPTS/lib_apt.sh
. $CIMAN_DOCKER_SCRIPTS/lib_yum.sh

must_be_called_by_docker_build

echo_log
echo_log "Starting  $(basename $0)"

do_git_config vpp
for branch in ${VPP_BRANCHES[$OS_NAME]} ; do
    do_git_branch $branch

  # Install OS packages
  make_vpp "install-dep" $branch
  make_vpp "centos-pyyaml" $branch
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
  make_vpp_test "test-dep" $branch
  make_vpp_test "doc" $branch
  make_vpp test-wipe $branch
  make_vpp "bootstrap-doxygen" $branch

  # Install google-chrome for VPP coverity job
  if [ "$OS_ID" = "ubuntu" ] ; then
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    dpkg -i google-chrome-stable_current_amd64.deb || true
    apt-get install -f -y
  fi

  # Dump packages installed
  case "$DOCKERFILE_FROM" in
    *ubuntu*)
      dump_apt_package_list $branch
      ;;
    *debian*)
      dump_apt_package_list $branch
      ;;
    *centos*)
      dump_yum_package_list $branch
      ;;
  esac
done

echo_log -e "Completed $(basename $0)!\n\n=========="
