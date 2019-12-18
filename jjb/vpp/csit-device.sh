#!/usr/bin/env bash

# Copyright (c) 2019 Cisco and/or its affiliates.
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

# Clone CSIT git repository and proceed with entry script located there.
#
# Variables read:
# - WORKSPACE - Jenkins workspace to create csit subdirectory in.
# - CSIT_REF - Override ref of CSIT git repository to checkout.
# Directories updated:
# - ${WORKSPACE}/csit - Created, holding a checked out CSIT repository.
# - Multiple other side effects by entry script(s), see CSIT repository.

cd "${WORKSPACE}"
git clone https://gerrit.fd.io/r/csit --depth=1 --no-single-branch --no-checkout
pushd "${WORKSPACE}/csit"
if [[ -n "${CSIT_REF-}" ]]; then
    git fetch --depth=1 https://gerrit.fd.io/r/csit "${CSIT_REF}"
    git checkout FETCH_HEAD
else
    git checkout HEAD
fi
popd
csit_entry_dir="${WORKSPACE}/csit/resources/libraries/bash/entry"
source "${csit_entry_dir}/with_oper_for_vpp.sh" "per_patch_device.sh"
