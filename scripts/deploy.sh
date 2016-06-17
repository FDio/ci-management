#!/bin/bash

#
# Script created to automate RT #24343
#

#
# Copyright 2016 The Linux Foundation, Cisco Systems
#


PROJECT=${PROJECT:-'vpp'}
PROJECT_PFX=fd.io
NEXUSPROXY=${NEXUSPROXY:-nexus.fd.io}
VERSION=16.06
RELEASE_BRANCH=stable.1606

declare -A JAR_TAG=( [jvpp]=20160616.165833-38
                     [vppjapi]=20160616.165830-38 )

declare -a DEB_PKG_LIST=( vpp vpp-lib vpp-dev vpp-dbg vpp-dpdk-dkms vpp-dpdk-dev )
declare -a RPM_PKG_LIST=( vpp vpp-lib vpp-devel )
declare -a JAR_PKG_LIST=( jvpp vppjapi )

declare -a DEB_DISTRIBUTORS=( debian ubuntu )
declare -a RH_DISTRIBUTORS=( redhat centos )

declare -a SUPPORTED_DISTRIBUTORS=( ubuntu centos )

declare -a SUPPORTED_DISTS=( trusty xenial centos7 )

declare -A REL_VER_MAP=( [centos6]=6
                         [centos7]=7
                         [trusty]=14.04
                         [xenial]=16.04
                         [yakkity]=16.06
                         [wheezy]=7
                         [jessie]=8
                         [stretch]=9
                       )
                         
declare -A DIST_RELEASE_MAP=( [redhat]="rhel6 rhel7"
                              [centos]="centos6 centos7"
                              [ubuntu]="trusty xenial yakkity"
                              [debian]="wheezy jessie stretch sid"
                            )

SRC_PFX=${PROJECT_PFX}.${RELEASE_BRANCH}

# ci-management root is one directory up from this script
CI_MGMT=$(realpath $(dirname $(realpath $0))/..)

#
# use functions common to maven push
#
source ${CI_MGMT}/jjb/scripts/maven_push_functions.sh

containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

if [ -n ${MAVEN_SELECTOR} ]
then
    MVN=${MVN:-"${HOME}/tools/hudson.tasks.Maven_MavenInstallation/${MAVEN_SELECTOR}/bin/mvn"}
else
    MVN=$(which mvn)
fi

REPO_NAME=${REPO_NAME:-${PROJECT}}

# On our target platforms, JAVA_HOME is two directories up from the
# java symlink in the path
export JAVA_HOME=${JAVA_HOME:-$(realpath $(which java) | sed -e 's:bin/java$::')}

REPO_ROOT=https://${NEXUSPROXY}/content/repositories
GLOBAL_SETTINGS_FILE=${GLOBAL_SETTINGS_FILE:-"/etc/maven/settings.xml"}
SETTINGS_FILE=${SETTINGS_FILE:-"${HOME}/.m2/settings.xml"}

DEB_ARCH=amd64
RH_ARCH=x86_64

JAR_VERSION="${VERSION}-SNAPSHOT"
RH_VERSION="${VERSION}-release.${RH_ARCH}"
DEB_VERSION="${VERSION}_${DEB_ARCH}"

for ARTIFACT_ID in "${DEB_PKG_LIST[@]}"
do
    for DISTRIBUTOR in "${DEB_DISTRIBUTORS[@]}"
    do
        for RELEASE in ${DIST_RELEASE_MAP[${DISTRIBUTOR}]}
        do
            echo "Release: ${RELEASE}"
            containsElement ${UBUNTU_DIST} ${SUPPORTED_DISTS} || continue

            for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
            ARCHIVE_AREA='main'
            REPO="${DISTRIBUTOR}.${UBUNTU_DIST}.${ARCHIVE_AREA}"
            SRC_REPO="${SRC_PFX}.${REPO}"
            DST_REPO="${PROJECT_PFX}.${REPO}"

            BASENAME="${ARTIFACT_ID}-${DEB_VERSION}.deb"

            mkdir -p ${SRC_REPO}
            wget -c -P ${SRC_REPO} "${REPO_ROOT}/${SRC_REPO}/io/fd/${REPO_NAME}/${ARTIFACT_ID}/${DEB_VERSION}/${BASENAME}"

            #        debfile=$1                repoId=$2     url=$3
            echo push_deb "${SRC_REPO}/${BASENAME}" "${DST_REPO}" "${REPO_ROOT}/${DST_REPO}"
        done
    done
done

for ARTIFACT_ID in "${RPM_PKG_LIST[@]}"
do
    for RH_DIST in "${RH_DISTS[@]}"
    do
        for CENTOS_DIST in "${CENTOS_DIST[@]}"
        do

            SRC_REPO="${SRC_PFX}.${CENTOS_DIST}"
            DST_REPO="${PROJECT_PFX}.${CENTOS_DIST}"

            mkdir -p ${SRC_REPO}
            BASENAME="${ARTIFACT_ID}-${RH_VERSION}.rpm"

            wget -c -P ${SRC_REPO} "${REPO_ROOT}/${SRC_REPO}/io/fd/${REPO_NAME}/${ARTIFACT_ID}/${RH_VERSION}/${BASENAME}"

            #        rpmfile=$1                repoId=$2     url=$3
            echo push_rpm "${SRC_REPO}/${BASENAME}" "${DST_REPO}" "${REPO_ROOT}/${DST_REPO}"

        done
    done
done

for ARTIFACT_ID in "${JAR_PKG_LIST[@]}"
do
    SRC_REPO=${PROJECT_PFX}.snapshot
    DST_REPO=${PROJECT_PFX}.release

    mkdir -p ${SRC_REPO}
    BASENAME="${ARTIFACT_ID}-${VERSION}-${JAR_TAG[${ARTIFACT_ID}]}.jar"

    wget -c -P "${SRC_REPO}" "${REPO_ROOT}/${SRC_REPO}/io/fd/${REPO_NAME}/${ARTIFACT_ID}/${JAR_VERSION}/${BASENAME}"

    #        jarfile=$1                repoId=$2     url=$3
    echo push_jar "${SRC_REPO}/${BASENAME}" "${DST_REPO}" "${REPO_ROOT}/${DST_REPO}"
done

