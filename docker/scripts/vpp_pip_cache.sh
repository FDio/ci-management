#! /bin/bash

set -euxo pipefail

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. $CIMAN_DOCKER_SCRIPTS/lib_vpp.sh

must_be_called_by_docker_build

echo_log
echo_log "Starting  $(basename $0)"

do_git_pull vpp
for branch in ${VPP_BRANCHES[$OS_NAME]} ; do
  do_git_branch $branch
  if [ "$OS_ID" = "centos" ] ; then
    # Required on aarch64, but best to do it for all
    perl -i -p -e \
       's/debuginfo\.centos\.org/mirror\.facebook\.net\/centos-debuginfo/g' \
       /etc/yum.repos.d/*.repo
    # Required on centos to install virualenv for 'make test'
    make_vpp $branch "install-dep"
  elif [ "$OS_ID" = "ubuntu" ] ; then
    # TODO: fix VPP stable/2005 bug in sphinx-make.sh
    #       which fails on 'yum install python3-venv'
    #       that does not exist.
    # 'Make docs jobs are only run on ubuntu executors
    #  so only run for ubuntu build executors until fixed.
    make_vpp $branch "docs-venv"
  fi
  make_vpp_test $branch "test-dep"
done

echo_log -e "Completed $(basename $0)!\n\n=========="
