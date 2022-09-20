#!/bin/bash

# Copyright (c) 2022 Cisco and/or its affiliates.
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

echo "---> jjb/scripts/vpp/gcc-build.sh"

set -euxo pipefail

line="*************************************************************************"
OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_ARCH=$(uname -m)
DRYRUN="${DRYRUN:-}"
BUILD_RESULT="SUCCESSFULLY COMPLETED"
BUILD_ERROR=""
RETVAL="0"

echo "sha1sum of this script: ${0}"
sha1sum $0
export CC=gcc

make_build_release_build_test_gcov_sanity() {
    if ! make UNATTENDED=yes install-dep ; then
        BUILD_ERROR="FAILED 'make install-dep'"
        return
    fi
    if ! make UNATTENDED=yes install-ext-deps ; then
        BUILD_ERROR="FAILED 'make install-ext-deps'"
        return
    fi
    if ! make UNATTENDED=yes build-release ; then
        BUILD_ERROR="FAILED 'make build'"
        return
    fi
    if ! make UNATTENDED=yes build ; then
        BUILD_ERROR="FAILED 'make build'"
        return
    fi
    if [ -n "${MAKE_PARALLEL_JOBS}" ] ; then
        TEST_JOBS="${MAKE_PARALLEL_JOBS}"
        echo "Testing VPP with ${TEST_JOBS} cores."
    else
        TEST_JOBS="auto"
        echo "Testing VPP with automatically calculated number of cores. " \
             "See test logs for the exact number."
    fi
    # TODO: Add 'smoke test' env var to select smoke test cases
    #       then update this accordingly.  For now pick a few basic suites...
    MAKE_TEST_SUITES="vlib vppinfra vpe_api vapi cli bihash"
    for suite in $MAKE_TEST_SUITES ; do
        if ! make UNATTENDED=yes TESTS_GCOV=1 TEST_JOBS="$TEST_JOBS" TEST=$suite test ; then
            BUILD_ERROR="FAILED 'make TESTS_GCOV=1 TEST_JOBS=$TEST_JOBS TEST=$suite test'!"
            return
        fi
        if ! make UNATTENDED=yes TESTS_GCOV=1 TEST_JOBS="$TEST_JOBS" TEST=$suite test-debug ; then
            BUILD_ERROR="FAILED 'make TESTS_GCOV=1 TEST_JOBS=$TEST_JOBS TEST=$suite test-debug'!"
            return
        fi
    done
}

if [ "${DRYRUN,,}" != "true" ] ; then
    make_build_release_build_test_gcov_sanity
fi
if [ -n "$BUILD_ERROR" ] ; then
    BUILD_RESULT="$BUILD_ERROR"
    RETVAL="1"
fi
echo -e "\n$line\n* VPP ${OS_ID^^}-${OS_VERSION_ID}-${OS_ARCH^^} GCC BUILD $BUILD_RESULT\n$line\n"
exit $RETVAL
