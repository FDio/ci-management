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
# - CSIT_REF - Ref of CSIT git repository to checkout.
# Directories updated:
# - ${WORKSPACE}/csit - Created, holding a checked out CSIT repository.

cd "${WORKSPACE}"
git clone https://gerrit.fd.io/r/csit --depth 1 --single-branch --no-checkout
pushd "${WORKSPACE}/csit"
# TODO: Is there a way for "git clone" to fetch a ref instead of a branch?
git fetch https://gerrit.fd.io/r/csit "${CSIT_REF}"
git checkout FETCH_HEAD
popd
source "${WORKSPACE}/csit/resources/libraries/bash/entry/per_patch_perf.sh"
