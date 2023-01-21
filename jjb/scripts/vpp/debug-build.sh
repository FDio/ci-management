#!/bin/bash

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

echo "---> jjb/scripts/vpp/debug-build.sh"

set -euxo pipefail

line="*************************************************************************"
OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_ARCH=$(uname -m)
DRYRUN="${DRYRUN:-}"
MAKE_PARALLEL_JOBS="${MAKE_PARALLEL_JOBS:-}"
BUILD_RESULT="SUCCESSFULLY COMPLETED"
BUILD_ERROR=""
RETVAL="0"

# run with ASAN on
# disable ASAN for now in the debug build - it's broken with PAPI
# in make test transitioning to unix sockets
# export VPP_EXTRA_CMAKE_ARGS='-DVPP_ENABLE_SANITIZE_ADDR=ON'

make_build_test_debug() {
    if ! make UNATTENDED=yes install-dep ; then
        BUILD_ERROR="FAILED 'make install-dep'"
        return
    fi
    if ! make UNATTENDED=yes install-ext-deps ; then
        BUILD_ERROR="FAILED 'make install-ext-deps'"
        return
    fi
    if ! make UNATTENDED=yes build ; then
        BUILD_ERROR="FAILED 'make build'"
        return
    fi
    if grep -q "${OS_ID}-${OS_VERSION_ID}" <<< "${MAKE_TEST_OS}"; then
        if [ -n "${MAKE_PARALLEL_JOBS}" ] ; then
            TEST_JOBS="${MAKE_PARALLEL_JOBS}"
            echo "Testing VPP with ${TEST_JOBS} cores."
        else
            TEST_JOBS="auto"
            echo "Testing VPP with automatically calculated number of cores. " \
                "See test logs for the exact number."
        fi
        if ! make UNATTENDED=yes COMPRESS_FAILED_TEST_LOGS=yes \
                TEST_JOBS="$TEST_JOBS" test-debug ; then
            BUILD_ERROR="FAILED 'make UNATTENDED=yes COMPRESS_FAILED_TEST_LOGS=yes TEST_JOBS=$TEST_JOBS test-debug'"
            return
        fi
    else
        echo "Skip running 'make test-debug' on ${OS_ID}-${OS_VERSION_ID}"
    fi
}

# clang is not working with ASAN right now - see change 27268
# also, it does not work with gcc-7, we need gcc-8 at least
# on ubuntu 20.04 executor the gcc is gcc9
if [ "${DRYRUN,,}" != "true" ] ; then
    make_build_test_debug
fi
if [ -n "$BUILD_ERROR" ] ; then
    BUILD_RESULT="$BUILD_ERROR"
    RETVAL="1"
fi
echo -e "\n$line\n* VPP ${OS_ID^^}-${OS_VERSION_ID}-${OS_ARCH^^} DEBUG BUILD $BUILD_RESULT\n$line\n"
exit $RETVAL
