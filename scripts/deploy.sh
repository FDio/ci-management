#!/bin/bash

#
# Script created to automate RT #24343
#

# Copyright 2016 The Linux Foundation <cjcollier@linuxfoundation.org>
if [ -n ${MAVEN_SELECTOR} ]
then
    MVN=${MVN:-"${HOME}/tools/hudson.tasks.Maven_MavenInstallation/${MAVEN_SELECTOR}/bin/mvn"}
else
    MVN=/usr/bin/mvn
fi

REPO_NAME=${REPO_NAME:-${PROJECT}}

BASEURL="${NEXUSPROXY}/content/repositories/fd.io."
BASEREPOID='fdio-'

JAVA_HOME=${JAVA_HOME:-"/usr/lib/jvm/java-8-openjdk-${DEB_ARCH}"}
export JAVA_HOME

REPO_NAME=${REPO_NAME:-vpp}
GROUP_ID=io.fd.${REPO_NAME}
ARCH=${DEB_ARCH}

NEXUSPROXY=${NEXUSPROXY:nexus.fd.io}
REPO_ROOT=${https://${NEXUSPROXY}/content/repositories
GLOBAL_SETTINGS_FILE=${GLOBAL_SETTINGS_FILE:-"/etc/maven/settings.xml"}
SETTINGS_FILE=${SETTINGS_FILE:-"${HOME}/.m2/settings.xml"}
CI_MGMT=$(realpath $(dirname $(realpath $0))/..)

source ${CI_MGMT}/vpp/scripts/maven_push_functions.sh

VERSION=16.06

DEB_ARCH=amd64
RH_ARCH=x86_64

JAR_VERSION="${VERSION}-SNAPSHOT"
RH_VERSION="${VERSION}-release.${RH_ARCH}"
DEB_VERSION="${VERSION}_${DEB_ARCH}"

declare -A JAR_TAG=( [jvpp]=20160616.165833-38 [vppjapi]=20160616.165830-38 )
SRC_PFX=fd.io.stable.1606

for ARTIFACT_ID in vpp-dbg vpp-lib vpp-dpdk-dkms vpp-dpdk-dev vpp-dev vpp
do
    for DEB_DIST in ubuntu.trusty.main ubuntu.xenial.main
    do
        SRC_REPO="${SRC_PFX}.${DEB_DIST}"
        DST_REPO="fd.io.${DEB_DIST}"

        BASENAME="${ARTIFACT_ID}-${DEB_VERSION}.deb"

        mkdir -p ${SRC_REPO}
        wget -c -P ${SRC_REPO} "${REPO_ROOT}/${SRC_REPO}/io/fd/${REPO_NAME}/${ARTIFACT_ID}/${DEB_VERSION}/${BASENAME}"

        push_deb "${SRC_REPO}/${BASENAME}" "${DST_REPO}" "${REPO_ROOT}/${DST_REPO}"
    done
done

for ARTIFACT_ID in vpp vpp-lib vpp-devel
do
    for RH_DIST in centos7
    do
        SRC_REPO="${SRC_PFX}.${RH_DIST}"
        DST_REPO="fd.io.${RH_DIST}"

        mkdir -p ${SRC_REPO}

        BASENAME="${ARTIFACT_ID}-${RH_VERSION}.rpm"

        wget -c -P ${SRC_REPO} "${REPO_ROOT}/${SRC_REPO}/io/fd/${REPO_NAME}/${ARTIFACT_ID}/${RH_VERSION}/${BASENAME}"

        #maven_push "${ARTIFACT_ID}" "${RH_VERSION}" "rpm" "${DST_REPO}" "${SRC_REPO}/${BASENAME}"
        push_rpm "${SRC_REPO}/${BASENAME}" "${DST_REPO}" "${REPO_ROOT}/${DST_REPO}"

    done
done

for ARTIFACT_ID in jvpp vppjapi
do
    SRC_REPO=fd.io.snapshot
    DST_REPO=fd.io.release

    mkdir -p ${SRC_REPO}

    BASENAME="${ARTIFACT_ID}-${VERSION}-${JAR_TAG[${ARTIFACT_ID}]}.jar"
    wget -c -P ${SRC_REPO} "${REPO_ROOT}/${SRC_REPO}/io/fd/${REPO_NAME}/${ARTIFACT_ID}/${JAR_VERSION}/${BASENAME}"

#    maven_push "${ARTIFACT_ID}" "${VERSION}" "jar" "${DST_REPO}" "${SRC_REPO}/${BASENAME}"
    push_jar "${SRC_REPO}/${BASENAME}" "${DST_REPO}" "${REPO_ROOT}/${DST_REPO}" "${VERSION}"
done

