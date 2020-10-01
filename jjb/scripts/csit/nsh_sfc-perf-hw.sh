#!/bin/bash
echo "---> jjb/scripts/csit/nsh_sfc-perf-hw.sh"

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

# execute  nsh_sfc bootstrap script if it exists
if [ ! -e bootstrap-verify-perf-nsh_sfc.sh ]
then
    echo 'ERROR: No bootstrap-verify-perf-nsh_sfc.sh found'
    exit 1
fi

# make sure that bootstrap-verify-perf.sh is executable
chmod +x bootstrap-verify-perf-nsh_sfc.sh
# run the script
if [ ${STREAM} == 'master' ]; then
    ./bootstrap-verify-perf-nsh_sfc.sh ${STREAM} ${OS}
else
    ./bootstrap-verify-perf-nsh_sfc.sh 'stable.'${STREAM} ${OS}
fi

# vim: ts=4 ts=4 sts=4 et :
