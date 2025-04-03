#!/usr/bin/env bash

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

echo "---> jjb/scripts/csit/perf-timed.sh"

set -exuo pipefail

# Clone CSIT git repository and proceed with entry script located there.
#
# Variables read:
# - WORKSPACE - Jenkins workspace to create csit subdirectory in.
# - GIT_URL - Git clone URL
# - GERRIT_BRANCH - Jenkins configured GERRIT_BRANCH parameter equal to required
#   CSIT branch.
# - CSIT_REF - Override ref of CSIT git repository to checkout.
# Directories updated:
# - ${WORKSPACE}/csit - Created, holding a checked out CSIT repository.
# - Multiple other side effects by entry script(s), see CSIT repository.

cd "${WORKSPACE}"
git clone "${GIT_URL}" --depth=1 --no-single-branch --no-checkout
pushd "${WORKSPACE}/csit"
if [[ -n "${CSIT_REF-}" ]]; then
    git fetch --depth=1 "${GIT_URL}" "${CSIT_REF}"
    git checkout FETCH_HEAD
else
    git checkout "${GERRIT_BRANCH}"
fi
popd
csit_entry_dir="${WORKSPACE}/csit/resources/libraries/bash/entry"
source "${csit_entry_dir}/with_oper_for_vpp.sh" "bootstrap_verify_perf.sh"
cp -R "${WORKSPACE}/csit/archives" "${WORKSPACE}/archives" || true
