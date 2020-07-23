#!/bin/bash
# basic build script example
set -xe -o pipefail

OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')

echo OS_ID: $OS_ID
echo OS_VERSION_ID: $OS_VERSION_ID

# do nothing but print the current slave hostname
hostname
export CCACHE_DIR=/tmp/ccache
if [ -d $CCACHE_DIR ];then
    echo $CCACHE_DIR exists
    du -sk $CCACHE_DIR
else
    echo $CCACHE_DIR does not exist.  This must be a new slave.
fi

echo "cat /etc/bootstrap.sha"
if [ -f /etc/bootstrap.sha ];then
    cat /etc/bootstrap.sha
else
    echo "Cannot find cat /etc/bootstrap.sha"
fi

echo "cat /etc/bootstrap-functions.sha"
if [ -f /etc/bootstrap-functions.sha ];then
    cat /etc/bootstrap-functions.sha
else
    echo "Cannot find cat /etc/bootstrap-functions.sha"
fi

echo "sha1sum of this script: ${0}"
sha1sum $0

echo "CC=${CC}"
echo "IS_CSIT_VPP_JOB=${IS_CSIT_VPP_JOB}"
# If and only if we are doing verify *after* make verify was made to work
# and we are not a CSIT job just building packages, then use make verify,
# else use make pkg-verify.

export TEST_JOBS="auto"
if [ "x${MAKE_PARALLEL_FLAGS}" != "x" ]
then
  echo "Building VPP. Number of cores for build set with" \
       "MAKE_PARALLEL_FLAGS='${MAKE_PARALLEL_FLAGS}'."
fi

if [ "x${MAKE_PARALLEL_JOBS}" != "x" ]
then
  export TEST_JOBS="${MAKE_PARALLEL_JOBS}"
  if [ "x${MAKE_PARALLEL_FLAGS}" == "x" ]
  then
    echo "Building VPP. Number of cores for build set with" \
         "MAKE_PARALLEL_JOBS='${MAKE_PARALLEL_JOBS}'."
  fi
elif [ "x${MAKE_PARALLEL_FLAGS}" == "x" ]
then
  echo "Building VPP. Number of cores not set, " \
       "using build default ($(grep -c ^processor /proc/cpuinfo))."
fi

echo "Testing VPP with ${TEST_JOBS} cores."

if (git log --oneline | grep 37682e1 > /dev/null 2>&1) && \
        [ "x${IS_CSIT_VPP_JOB}" != "xTrue" ]
then
    echo "Building using \"make verify\""
    [ "x${DRYRUN}" == "xTrue" ] || make UNATTENDED=yes verify
else
    echo "Building using \"make pkg-verify\""
    [ "x${DRYRUN}" == "xTrue" ] || make UNATTENDED=yes pkg-verify
fi

if [ "x${VPP_REPO}" == "x1" ]; then
    if [ "x${REBASE_NEEDED}" == "x1" ]; then
        echo "This patch to vpp is based on an old point in the tree that is likely"
        echo "to fail verify."
        echo "PLEASE REBASE PATCH ON THE CURRENT HEAD OF THE VPP REPO"
        exit 1
    fi
fi

local_arch=$(uname -m)

echo "*******************************************************************"
echo "* VPP ${local_arch^^} BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
