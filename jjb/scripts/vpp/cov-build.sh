#!/bin/bash

# Copyright (c) 2023 Cisco and/or its affiliates.
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

echo "---> jjb/scripts/vpp/cov-build.sh"

set -euxo pipefail

line="*************************************************************************"
# Don't build anything if this is a merge job.
if [[ ${JOB_NAME} == *merge* ]] ; then
    echo -e "\n$line\nSkipping build."
    exit 0
fi

OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_ARCH=$(uname -m)
DRYRUN="${DRYRUN:-}"
IS_CSIT_VPP_JOB="${IS_CSIT_VPP_JOB:-}"
MAKE_PARALLEL_FLAGS="${MAKE_PARALLEL_FLAGS:-}"
MAKE_PARALLEL_JOBS="${MAKE_PARALLEL_JOBS:-}"
MAKE_TEST_OS="${MAKE_TEST_OS:-ubuntu-22.04}"
MAKE_TEST_MULTIWORKER_OS="${MAKE_TEST_MULTIWORKER_OS:-debian-12}"
VPPAPIGEN_TEST_OS="${VPPAPIGEN_TEST_OS:-${MAKE_TEST_OS}}"
BUILD_RESULT="SUCCESSFULLY COMPLETED"
BUILD_ERROR=""
RETVAL="0"

if [ -n "${MAKE_PARALLEL_FLAGS}" ] ; then
  echo "Building VPP. Number of cores for build set with" \
       "MAKE_PARALLEL_FLAGS='${MAKE_PARALLEL_FLAGS}'."
elif [ -n "${MAKE_PARALLEL_JOBS}" ] ; then
  echo "Building VPP. Number of cores for build set with" \
       "MAKE_PARALLEL_JOBS='${MAKE_PARALLEL_JOBS}'."
else
    echo "Building VPP. Number of cores not set," \
         "using build default ($(grep -c ^processor /proc/cpuinfo))."
fi

make_test_coverage_report() {
    if ! make UNATTENDED=yes install-dep ; then
        BUILD_ERROR="FAILED 'make install-dep'"
        return
    fi
    if ! make UNATTENDED=yes install-ext-deps ; then
        BUILD_ERROR="FAILED 'make install-ext-deps'"
        return
    fi
    if ! make UNATTENDED=yes test-dep ; then
        BUILD_ERROR="FAILED 'make test-dep'"
        return
    fi
    if ! make UNATTENDED=yes CCACHE_DISABLE=1 pkg-verify ; then
        BUILD_ERROR="FAILED 'make pkg-verify'"
	    return
    fi
    if [ "${IS_CSIT_VPP_JOB,,}" == "true" ] ; then
	    # CSIT jobs don't need to run make test
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
    if grep -q "${OS_ID}-${OS_VERSION_ID}" <<< "${VPPAPIGEN_TEST_OS}"; then
        if ! src/tools/vppapigen/test_vppapigen.py ; then
            BUILD_ERROR="FAILED src/tools/vppapigen/test_vppapigen.py"
            return
        fi
    fi
    if grep -q "${OS_ID}-${OS_VERSION_ID}" <<< "${MAKE_TEST_OS}"; then
        if ! make COMPRESS_FAILED_TEST_LOGS=yes TEST_JOBS="$TEST_JOBS" CCACHE_DISABLE=1 test-cov-both ; then
            BUILD_ERROR="FAILED 'make test-cov'"
            return
        fi
    else
        echo "Skip running 'make test-cov' on ${OS_ID}-${OS_VERSION_ID}"
    fi
}

if [ "${DRYRUN,,}" != "true" ] ; then
    make_test_coverage_report
fi
if [ -n "$BUILD_ERROR" ] ; then
    BUILD_RESULT="$BUILD_ERROR"
    RETVAL="1"
fi
echo -e "\n$line\n* VPP ${OS_ID^^}-${OS_VERSION_ID}-${OS_ARCH^^}" \
        "TEST COVERAGE REPORT $BUILD_RESULT\n$line\n"
exit $RETVAL
