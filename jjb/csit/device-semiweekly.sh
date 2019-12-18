#!/usr/bin/env bash

# Copyright (c) 2018 Cisco and/or its affiliates.
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
# - BRANCH_ID - CSIT operational branch to be used for test.
# Directories updated:
# - ${WORKSPACE}/csit - Created, holding a checked out CSIT repository.
# - Multiple other side effects by entry script(s), see CSIT repository.

cd "${WORKSPACE}"
git clone https://gerrit.fd.io/r/csit --depth=1 --no-single-branch --no-checkout
# Check BRANCH_ID value.
if [[ -z "${BRANCH_ID-}" ]]; then
    echo "BRANCH_ID not provided => 'oper' belonging to master will be used."
    BRANCH_ID="oper"
fi
pushd "${WORKSPACE}/csit"
# Get the latest verified version of the required branch.
BRANCH_NAME=$(echo $(git branch -r | grep -E "${BRANCH_ID}-[0-9]+" | tail -n 1))
if [[ -z "${BRANCH_NAME-}" ]]; then
    echo "No verified CSIT branch found - exiting!"
    exit 1
fi
# Remove 'origin/' from the branch name.
BRANCH_NAME=$(echo ${BRANCH_NAME#origin/})
# Checkout the required csit branch.
git checkout "${BRANCH_NAME}"
popd
csit_entry_dir="${WORKSPACE}/csit/resources/libraries/bash/entry"
source "${csit_entry_dir}/bootstrap_vpp_device.sh"
