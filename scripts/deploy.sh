#!/bin/bash

#
# Script created to automate RT #24343
#

#
# Copyright 2016 The Linux Foundation, Cisco Systems
#


PROJECT=${PROJECT:-'vpp'}
PROJECT_PFX=fd.io
PROJECT_DOMAIN=fd.io
VERSION=16.06

RELEASE_BRANCH=stable.$(echo ${VERSION} | sed -e 's:\.::')

declare -A JAR_TAG=( [jvpp]=20160616.165833-38
                     [vppjapi]=20160616.165830-38 )

declare -A PKG_LIST=( [deb]="vpp vpp-lib vpp-dev vpp-dbg vpp-dpdk-dkms vpp-dpdk-dev"
                      [rpm]="vpp vpp-lib vpp-devel"
                      [jar]="jvpp vppjapi" )

declare -a DEB_DISTRIBUTORS=( debian ubuntu )
declare -a RH_DISTRIBUTORS=( redhat centos )

declare -a SUPPORTED_DISTRIBUTORS=( centos )

declare -a SUPPORTED_RELEASES=( trusty xenial centos7 )

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
                              [centos]="centos7 centos6"
                              [ubuntu]="trusty xenial yakkity"
                              [debian]="wheezy jessie stretch sid"
                            )

NEXUSPROXY=${NEXUSPROXY:-"nexus.${PROJECT_DOMAIN}"}

PFX_PATH=$(perl -e 'print( join(q{/},reverse(split(/\./,$ARGV[0]))) )' "${PROJECT_PFX}")
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

if [ -n "${MAVEN_SELECTOR}" ]
then
    MVN=${MVN:-"${HOME}/tools/hudson.tasks.Maven_MavenInstallation/${MAVEN_SELECTOR}/bin/mvn"}
else
    MVN="echo $(which mvn)"
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


JAR_SRC_VERSION="${VERSION}-SNAPSHOT"
JAR_VERSION=
RPM_VERSION="${VERSION}-release.${RH_ARCH}"
DEB_VERSION="${VERSION}_${DEB_ARCH}"

for DISTRIBUTOR in "${SUPPORTED_DISTRIBUTORS[@]}"
do
    echo "distributor: ${DISTRIBUTOR}"
    read -ra RELEASES <<< "${DIST_RELEASE_MAP[${DISTRIBUTOR}]}"

    for RELEASE in ${RELEASES}
    do
        echo "release: ${RELEASE}"
        containsElement ${RELEASE} ${SUPPORTED_RELEASES[@]} || continue
        if containsElement ${DISTRIBUTOR} ${RH_DISTRIBUTORS[@]}
        then
            PKG_TYPE=rpm

#           TODO: REPO="${DISTRIBUTOR}.${RELEASE}"
            REPO="${RELEASE}"
            PKG_VERSION="${RPM_VERSION}"
        elif containsElement ${DISTRIBUTOR} ${DEB_DISTRIBUTORS[@]}
        then
            PKG_TYPE=deb

            ARCHIVE_AREA='main'
            REPO="${DISTRIBUTOR}.${RELEASE}.${ARCHIVE_AREA}"
            PKG_VERSION="${DEB_VERSION}"
        else
            echo "unrecognized distributor, ${DISTRIBUTOR}"
            exit -1
        fi

        SRC_REPO="${SRC_PFX}.${REPO}"
        DST_REPO="${PROJECT_PFX}.${REPO}"

        mkdir -p ${SRC_REPO}

        read -ra PACKAGES <<< "${PKG_LIST[${PKG_TYPE}]}"

        for ARTIFACT_ID in "${PACKAGES[@]}"
        do
            BASENAME="${ARTIFACT_ID}-${PKG_VERSION}.${PKG_TYPE}"
            echo "fetching ${REPO_NAME}/${ARTIFACT_ID}/${PKG_VERSION}/${BASENAME}"
            wget -q -c -P "${SRC_REPO}" "${REPO_ROOT}/${SRC_REPO}/${PFX_PATH}/${REPO_NAME}/${ARTIFACT_ID}/${PKG_VERSION}/${BASENAME}"

            #        debfile=$1                repoId=$2     url=$3
            "push_${PKG_TYPE}" "${SRC_REPO}/${BASENAME}" "${DST_REPO}" "${REPO_ROOT}/${DST_REPO}"
        done
    done
done

for ARTIFACT_ID in "${JAR_PKG_LIST[@]}"
do
    SRC_REPO=${PROJECT_PFX}.snapshot
    DST_REPO=${PROJECT_PFX}.release

    mkdir -p ${SRC_REPO}
    BASENAME="${ARTIFACT_ID}-${VERSION}-${JAR_TAG[${ARTIFACT_ID}]}.jar"

    wget -q -c -P "${SRC_REPO}" "${REPO_ROOT}/${SRC_REPO}/${PFX_PATH}/${REPO_NAME}/${ARTIFACT_ID}/${JAR_SRC_VERSION}/${BASENAME}"

    #             jarfile=$1                repoId=$2     url=$3                     version=$4
    push_jar "${SRC_REPO}/${BASENAME}" "${DST_REPO}" "${REPO_ROOT}/${DST_REPO}" "${VERSION}"
done

