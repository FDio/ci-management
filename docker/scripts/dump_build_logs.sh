#! /bin/bash

set -euxo pipefail

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. $CIMAN_DOCKER_SCRIPTS/lib_common.sh

dump_build_logs() {
  local set_opts=$-
  grep -q e <<< $set_opts && set +e # disable exit on errors

  # Find errors
  local found="$(grep -nisH error $DOCKER_BUILD_LOG_DIR/*-bld.log)"
  if [ -n "$found" ] ; then
    echo -e "\nErrors found in build log files:\n$found\n"
  else
    echo -e "\nNo errors found in build logs\n"
  fi

  # Find warnings
  found="$(grep -nisH warning $DOCKER_BUILD_LOG_DIR/*-bld.log)"
  if [ -n "$found" ] ; then
    echo -e "\nWarnings found in build log files:\n$found\n"
  else
    echo -e "\nNo warnings found in build logs\n"
  fi

  grep -q e <<< $set_opts && set -e # re-enable exit on errors
}

dump_cache_files() {
  local cache_files_log="$DOCKER_BUILD_LOG_DIR/cached_files.json"
  tree -a --timefmt "+%Y-%m-%d %H:%M:%S" --prune /root
  tree -afJ --timefmt "+%Y-%m-%d %H:%M:%S" --prune -o $cache_files_log /root
}

must_be_called_by_docker_build
dump_cache_files
dump_build_logs
dump_echo_log
