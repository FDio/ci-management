#!/bin/bash
# Copyright (c) 2018 Huawei Technologies Co.,Ltd.
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

# Clone csit and start tests
git clone https://gerrit.fd.io/r/csit

# If the git clone fails, complain clearly and exit
if [ $? != 0 ]; then
    echo "Failed to run: git clone https://gerrit.fd.io/r/csit"
    exit 1
fi

mkdir -p ./csit/dmm/

# Move the dmm to the csit dir
rsync -av --progress --exclude="./csit" . ./csit/dmm/

cd csit

# execute dmm bootstrap script if it exists
if [ -e bootstrap-DMM.sh ]
then
    # make sure that bootstrap-DMM.sh is executable
    chmod +x bootstrap-DMM.sh
    # run the script
    ./bootstrap-DMM.sh
else
    echo 'ERROR: No bootstrap-DMM.sh found'
    exit 1
fi

# vim: ts=4 ts=4 sts=4 et :
