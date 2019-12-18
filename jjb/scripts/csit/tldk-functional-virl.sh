#!/bin/bash
# Copyright (c) 2017 Cisco and/or its affiliates.
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

set -xeu -o pipefail

# Clone tldk and start tests
git clone https://gerrit.fd.io/r/tldk

# If the git clone fails, complain clearly and exit
if [ $? != 0 ]; then
    echo "Failed to run: git clone https://gerrit.fd.io/r/tldk"
    exit 1
fi

# execute tldk bootstrap script if it exists
if [ -e bootstrap-TLDK.sh ]
then
    # make sure that bootstrap-TLDK.sh is executable
    chmod +x bootstrap-TLDK.sh
    # run the script
    ./bootstrap-TLDK.sh
else
    echo 'ERROR: No bootstrap-TLDK.sh found'
    exit 1
fi

# vim: ts=4 ts=4 sts=4 et :
