#!/bin/bash
# basic build script example
echo "---> build.sh"

set -xe -o pipefail

OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_ARCH=$(uname -m)

echo "BUILD OS: ${OS_ID}-${OS_VERSION_ID} ($OS_ARCH)"

# TODO: fix this to print nomad server hostname
# do nothing but print the current slave hostname
hostname

# TODO: Mount ccache volume into docker container, then enable this.
#
#export CCACHE_DIR=/scratch/docker-build/ccache
#if [ -d $CCACHE_DIR ];then
#    echo "ccache size:"
#    du -sh $CCACHE_DIR
#else
#    echo $CCACHE_DIR does not exist.
#fi

echo "sha1sum of this script: ${0}"
sha1sum $0

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

echo "*******************************************************************"
echo "* VPP ${OS_ID^^}-${OS_VERSION_ID}-${OS_ARCH^^} BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
