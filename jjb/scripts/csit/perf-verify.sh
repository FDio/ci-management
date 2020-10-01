#!/usr/bin/env bash
echo "---> jjb/scripts/csit/perf-verify.sh"

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

set -exuo pipefail

if [[ ${GERRIT_EVENT_TYPE} == 'comment-added' ]]; then
    TRIGGER=`echo ${GERRIT_EVENT_COMMENT_TEXT} \
        | grep -oE '(perftest$|perftest[[:space:]].+$)'`
else
    TRIGGER=''
fi
# Export test tags as string.
export TEST_TAG_STRING=${TRIGGER#$"perftest"}

csit_entry_dir="${WORKSPACE}/resources/libraries/bash/entry"
source "${csit_entry_dir}/bootstrap_verify_perf.sh"
