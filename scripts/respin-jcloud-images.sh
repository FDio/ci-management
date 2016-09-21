#!/bin/bash
# Copyright 2016 The Linux Foundation
set -e

SUPPORTED_PLATFORMS=(
  'Ubuntu 14.04 amd64'
  'Ubuntu 16.04 amd64'
  'CentOS 7 x86_64'
)

CI_MGMT=$(realpath $(dirname $(realpath $0))/..)

source ${CI_MGMT}/vagrant/lib/respin-functions.sh
source ${PVERC}

VAGRANT_DIR=${CI_MGMT}/vagrant/basebuild

RESEAL=true

# Fetch MVN package
MAVEN_MIRROR=apache.mirrors.tds.net
MAVEN_VERSION=3.3.9
MAVEN_FILENAME=apache-maven-${MAVEN_VERSION}-bin.tar.gz
MAVEN_RELEASE=http://${MAVEN_MIRROR}/maven/maven-3/${MAVEN_VERSION}/binaries/${MAVEN_FILENAME}

TRIES=10

wget -t ${TRIES} -q -O ${VAGRANT_DIR}/${MAVEN_FILENAME} ${MAVEN_RELEASE}

# Fetch EPEL package
EPEL_RPM=epel-release-latest-7.noarch.rpm
EPEL_RELEASE=https://dl.fedoraproject.org/pub/epel/${EPEL_RPM}

wget -t ${TRIES} -q -O ${VAGRANT_DIR}/${EPEL_RPM} ${EPEL_RELEASE}

echo nova: $(which nova)

export NETID=${NETID:-$(nova network-list | awk "/${CPPROJECT}/ {print \$2}")}

for PLATFORM in "${SUPPORTED_PLATFORMS[@]}"
do
    read -ra DVA <<< "${PLATFORM}"
    DIST="${DVA[0]}"
    VERSION="${DVA[1]}"
    ARCH="${DVA[2]}"
    DTYPE=$(dist_type ${DIST})

    # Respin images
    cd ${VAGRANT_DIR}
    respin_${DTYPE}_image "${DIST}" "${VERSION}" "${ARCH}"
done
