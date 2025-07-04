#!/bin/bash

# Copyright (c) 2024 Cisco and/or its affiliates.
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

echo "---> jjb/scripts/vpp/debug-hst.sh"

set -euxo pipefail

line="*************************************************************************"
OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_ARCH=$(uname -m)
DRYRUN="${DRYRUN:-}"
BUILD_RESULT="SUCCESSFULLY COMPLETED"
BUILD_ERROR=""
RETVAL="0"
HST_DIR="./extras/hs-test"

hst_build_run() {
    if ! make UNATTENDED=yes install-dep ; then
        BUILD_ERROR="FAILED 'make install-dep'"
        return
    fi
    if ! make UNATTENDED=yes install-ext-deps ; then
        BUILD_ERROR="FAILED 'make install-ext-deps'"
        return
    fi
    if ! make VERBOSE=true VPPSRC="$(pwd)" -C "$HST_DIR" build-debug ; then
        BUILD_ERROR="FAILED 'make -C $HST_DIR build-debug'"
        return
    fi
    if ! make VERBOSE=true VPPSRC="$(pwd)" -C "$HST_DIR" test-debug ; then
        BUILD_ERROR="FAILED 'make -C $HST_DIR test-debug'"
        return
    fi
}

if [ "${DRYRUN,,}" != "true" ] ; then
    echo "Check for system core files"
    ls -l /var/crash || true
    hst_build_run
    echo "Check for system core files"
    ls -l /var/crash || true
fi
if [ -n "$BUILD_ERROR" ] ; then
    BUILD_RESULT="$BUILD_ERROR"
    RETVAL="1"
fi
echo -e "\n$line\n* VPP ${OS_ID^^}-${OS_VERSION_ID}-${OS_ARCH^^}" \
        "DEBUG HostStack Test Suite $BUILD_RESULT\n$line\n"
exit $RETVAL
