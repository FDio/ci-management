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

# Currently this is just a direct call to CSIT checked-out script.
# We do not use source command, to make sure
# the called script choses the interpreter it needs.

echo "---> jjb/scripts/csit/tox.sh"

set -exuo pipefail

${WORKSPACE}/resources/libraries/bash/entry/tox.sh
