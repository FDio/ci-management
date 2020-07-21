#! /bin/bash

set -euxo pipefail

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. $CIMAN_DOCKER_SCRIPTS/lib_vpp.sh
. $CIMAN_DOCKER_SCRIPTS/lib_apt.sh
. $CIMAN_DOCKER_SCRIPTS/lib_yum.sh

must_be_called_by_docker_build

echo_log
echo_log "Starting  $(basename $0)"

do_git_pull vpp
for branch in ${VPP_BRANCHES[$OS_NAME]} ; do
  do_git_branch $branch
  make_vpp "install-dep" $branch
  if [ "$OS_ID" = "ubuntu" ] ; then
    # TODO: fix VPP stable/2005 bug in sphinx-make.sh
    #       which fails on 'yum install python3-venv'
    #       that does not exist.
    # 'Make docs jobs are only run on ubuntu executors
    #  so only run for ubuntu build executors until fixed.
    make_vpp "docs-venv" $branch
  fi
  make_vpp_test "test-dep" $branch
  make_vpp test-wipe $branch
  make_vpp "bootstrap-doxygen" $branch

  case $DOCKERFILE_FROM in
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
