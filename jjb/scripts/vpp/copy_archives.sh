#!/usr/bin/env bash

# Copyright (c) 2021 Cisco and/or its affiliates.
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

echo "---> jjb/scripts/vpp/copy_archives.sh"

set -xuo pipefail
set +e

# Copy robot archives from perf job to where archive macro needs them.
#
# This has to be a script separate from csit-perf.sh, run as publisher,
# because otherwise it is not easily possible to ensure this is executed
# also when there is a test case failure.
#
# This can be removed when all CSIT branches use correct archive directory.
# For fixed CSIT, the copy will fail, so errors are ignored everywhere.
#
# Variables read:
# - WORKSPACE - Jenkins workspace to create csit subdirectory in.
# Directories updated:
# - ${WORKSPACE}/archives/csit_current - Current patch results are copied here.
# - ${WORKSPACE}/archives/csit_parent - Parent patch results are copied here.

mkdir -p "${WORKSPACE}/archives"
cp -Rv "${WORKSPACE}/csit_current" "${WORKSPACE}/archives"
cp -Rv "${WORKSPACE}/csit_parent" "${WORKSPACE}/archives"
