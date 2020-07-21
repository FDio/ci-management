#! /bin/bash

set -euxo pipefail

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. $CIMAN_DOCKER_SCRIPTS/vpp_lib.sh
. $CIMAN_DOCKER_SCRIPTS/apt_lib.sh
. $CIMAN_DOCKER_SCRIPTS/yum_lib.sh

must_be_called_by_docker_build

echo_log
echo_log "Starting  $(basename $0)"

do_git_pull vpp
for branch in ${VPP_BRANCHES[$OS_NAME]} ; do
  do_git_branch $branch
  make_vpp $branch "install-dep"
  make_vpp $branch "bootstrap-doxygen"

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
