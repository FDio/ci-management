#! /bin/bash

set -euxo pipefail

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. $CIMAN_DOCKER_SCRIPTS/lib_common.sh

dump_build_logs() {
  local set_opts=$-
  grep -q e <<< $set_opts && set +e # disable exit on errors

  # Find errors
  local found="$(grep -nisH error $BUILD_LOG_DIR/*-bld.log)"
  if [ -n "$found" ] ; then
    echo -e "\nErrors found in build log files:\n$found\n"
  else
    echo -e "\nNo errors found in build logs\n"
  fi

  # Find warnings
  found="$(grep -nisH warning $BUILD_LOG_DIR/*-bld.log)"
  if [ -n "$found" ] ; then
    echo -e "\nWarnings found in build log files:\n$found\n"
  else
    echo -e "\nNo warnings found in build logs\n"
  fi

  grep -q e <<< $set_opts && set -e # re-enable exit on errors
}

must_be_called_by_docker_build
dump_build_logs
dump_echo_log
