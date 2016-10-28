#!/bin/bash
# basic build script example
set -e -o pipefail
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
    echo "Cannot find /etc/bootstrap.sha"
fi

echo "cat /etc/bootstrap-functions.sha"
if [ -f /etc/bootstrap-functions.sha ];then
    cat /etc/bootstrap-functions.sha
else
    echo "Cannot find /etc/bootstrap-functions.sha"
fi

echo "sha1sum of this script: ${0}"
sha1sum $0

if [ -n ${MVN} ]
then
  export MAVEN_HOME=$(dirname ${MVN})/..
else
  export MAVEN_HOME="/opt/apache/maven/"
fi

export PATH=${MAVEN_HOME}/bin:${PATH}

scripts/ci/verify.sh

echo "*******************************************************************"
echo "* NSH_SFC BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
