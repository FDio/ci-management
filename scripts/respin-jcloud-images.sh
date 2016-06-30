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

echo nova: $(which nova)

export NETID=${NETID:-$(nova network-list | awk "/${CPPROJECT}/ {print \$2}")}

for PLATFORM in "${SUPPORTED_PLATFORMS[@]}"
do
    read -ra DVA <<< "${PLATFORM}"
    DIST="${DVA[0]}"
    VERSION="${DVA[1]}"
    ARCH="${DVA[2]}"
    DTYPE=$(dist_type ${DIST})

    AGE_JSON=$(latest_src_age ${DIST} ${VERSION} ${ARCH});

    # only fetch new base image if our latest one is more than two weeks old
    if [ $(echo ${AGE_JSON} | jq .week) -ge "3" ]
    then
        # Acquire bootstrap images
        download_${DTYPE}_image "${DIST}" "${VERSION}" "${ARCH}"

        # Push images to openstack via glance
        create_${DTYPE}_image "${DIST}" "${VERSION}" "${ARCH}"
    fi

    # Respin images
    cd ${CI_MGMT}/vagrant/basebuild
    respin_${DTYPE}_image "${DIST}" "${VERSION}" "${ARCH}"
done
