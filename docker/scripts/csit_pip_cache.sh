#! /bin/bash

set -euxo pipefail

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. $CIMAN_DOCKER_SCRIPTS/lib_csit.sh

must_be_called_by_docker_build

echo_log
echo_log "Starting  $(basename $0)"

do_git_pull csit
for branch in ${CSIT_BRANCHES[$OS_NAME]} ; do
  do_git_branch $branch
  csit_pip_cache $branch
done

echo_log -e "Completed $(basename $0)!\n\n=========="
