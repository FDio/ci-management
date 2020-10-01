#!/bin/bash
echo "---> jjb/scripts/csit/vpp-functional-multilink.sh"

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

# execute csit bootstrap script if it exists
if [ -e bootstrap-multilink.sh ]
then
    # make sure that bootstrap.sh is executable
    chmod +x bootstrap-multilink.sh
    # run the script
    ./bootstrap-multilink.sh
else
    echo 'ERROR: No bootstrap-multilink.sh found'
    exit 1
fi

# vim: ts=4 ts=4 sts=4 et :
