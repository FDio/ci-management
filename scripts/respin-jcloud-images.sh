#!/bin/bash

set -e

CI_MGMT=$(realpath $(dirname $(realpath $0))/..)

# Copyright 2016 The Linux Foundation <cjcollier@linuxfoundation.org>
source ${CI_MGMT}/vagrant/lib/respin-functions.sh

source ${PVE_PATH}/bin/activate

# Acquire bootstrap images
#download_deb_image 'Ubuntu' '14.04' 'amd64'
#download_deb_image 'Ubuntu' '16.04' 'amd64'
#download_rh_image 'CentOS' '7' 'x86_64'

# Push images to openstack via glance
#create_deb_image 'Ubuntu' '14.04' 'amd64'
#create_deb_image 'Ubuntu' '16.04' 'amd64'
#create_rh_image 'CentOS' '7' 'x86_64'

# Respin images
respin_deb_image 'Ubuntu' '14.04' 'amd64'
respin_deb_image 'Ubuntu' '16.04' 'amd64'
respin_rh_image 'CentOS' '7' 'x86_64'
