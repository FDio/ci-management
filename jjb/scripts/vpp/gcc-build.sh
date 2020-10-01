#!/bin/bash
echo "---> jjb/scripts/vpp/gcc-build.sh"

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

set -xe -o pipefail

OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_ARCH=$(uname -m)

echo "BUILD OS: ${OS_ID}-${OS_VERSION_ID} ($OS_ARCH)"

# TODO: fix this to print nomad server hostname
# do nothing but print the current slave hostname
hostname

echo "sha1sum of this script: ${0}"
sha1sum $0
export CC=gcc

make UNATTENDED=yes install-dep
make UNATTENDED=yes install-ext-deps
make UNATTENDED=yes build
# TODO: Add 'smoke test' env var to select smoke test cases
#       then update this accordingly.  For now pick a few basic suites...
MAKE_TEST_SUITES="vlib vppinfra vpe_api vapi vom bihash"
for suite in $MAKE_TEST_SUITES ; do
    make UNATTENDED=yes GCOV_TESTS=1 TEST_JOBS=auto TEST=$suite test
    make UNATTENDED=yes GCOV_TESTS=1 TEST_JOBS=auto TEST=$suite test-debug
done

echo "*******************************************************************"
echo "* VPP GCC on ${OS_ID^^}-${OS_VERSION}-${OS_ARCH^^} BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
