#! /bin/bash

set -euxo pipefail

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. $CIMAN_DOCKER_SCRIPTS/lib_csit.sh
. $CIMAN_DOCKER_SCRIPTS/lib_vpp.sh

must_be_called_by_docker_build

echo_log
echo_log "Starting  $(basename $0)"

do_git_config csit
for vpp_branch in ${VPP_BRANCHES[$OS_NAME]} ; do
  csit_pip_cache $vpp_branch
done

echo_log -e "Completed $(basename $0)!\n\n=========="
