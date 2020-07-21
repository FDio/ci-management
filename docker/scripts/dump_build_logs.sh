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
export CIMAN_ROOT=${CIMAN_ROOT:-"$(dirname $(dirname $CIMAN_DOCKER_SCRIPTS))"}
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
