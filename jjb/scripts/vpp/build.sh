#!/bin/bash
# basic build script example

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

echo "---> jjb/scripts/vpp/build.sh"

set -xe -o pipefail

line="*************************************************************************"
# Don't build anything if this is a merge job being run when
# the git HEAD id is not the same as the Gerrit New Revision id.
if [[ ${JOB_NAME} == *merge* ]] && [ -n "$GERRIT_NEWREV" ] &&
       [ "$GERRIT_NEWREV" != "$GIT_COMMIT" ] ; then
    echo -e "\n$line\nSkipping build. A newer patch has been merged.\n$line\n"
    exit 0
fi
    
OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_ARCH=$(uname -m)

echo "sha1sum of this script: ${0}"
sha1sum $0

# TODO: Mount ccache volume into docker container, then enable this.
#
#export CCACHE_DIR=/scratch/docker-build/ccache
#if [ -d $CCACHE_DIR ];then
#    echo "ccache size:"
#    du -sh $CCACHE_DIR
#else
#    echo $CCACHE_DIR does not exist.
#fi

if [ "x${MAKE_PARALLEL_FLAGS}" != "x" ]
then
  echo "Building VPP. Number of cores for build set with" \
       "MAKE_PARALLEL_FLAGS='${MAKE_PARALLEL_FLAGS}'."
elif [ "x${MAKE_PARALLEL_JOBS}" != "x" ]
then
  echo "Building VPP. Number of cores for build set with" \
       "MAKE_PARALLEL_JOBS='${MAKE_PARALLEL_JOBS}'."
else
  echo "Building VPP. Number of cores not set, " \
       "using build default ($(grep -c ^processor /proc/cpuinfo))."
fi

echo "CC=${CC}"
echo "IS_CSIT_VPP_JOB=${IS_CSIT_VPP_JOB}"

# If we are not a CSIT job just building packages, then use make verify,
# else use make pkg-verify.
if [ "x${IS_CSIT_VPP_JOB}" != "xTrue" ]
then
    if [ "x${MAKE_PARALLEL_JOBS}" != "x" ]
    then
        export TEST_JOBS="${MAKE_PARALLEL_JOBS}"
        echo "Testing VPP with ${TEST_JOBS} cores."
    else
        export TEST_JOBS="auto"
        echo "Testing VPP with automatically calculated number of cores. " \
             "See test logs for the exact number."
    fi
    echo "Building using \"make verify\""
    [ "x${DRYRUN}" == "xTrue" ] || make UNATTENDED=yes verify
else
    echo "Building using \"make pkg-verify\""
    [ "x${DRYRUN}" == "xTrue" ] || make UNATTENDED=yes pkg-verify
fi

echo -e "\n$line\n* VPP ${OS_ID^^}-${OS_VERSION_ID}-${OS_ARCH^^} BUILD SUCCESSFULLY COMPLETED\n$line\n"
