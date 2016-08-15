#!/bin/bash

# Copyright 2016 The Linux Foundation

set -e

CI_MGMT=$(realpath $(dirname $(realpath $0))/..)
source ${CI_MGMT}/scripts/init-respin-env.sh

VAGRANT_DEFAULT_PROVIDER=openstack

CPPROJECT=${CPPROJECT:-fdio}
SERVER_NAME=${SERVER_NAME:-${USER}-vagrant}

STACK_PROVIDER=vexxhost
STACK_PORTAL=secure.${STACK_PROVIDER}.com
STACK_ID_SERVER=auth.${STACK_PROVIDER}.net

export OPENSTACK_AUTH_URL="https://${STACK_ID_SERVER}/v2.0/"
export OPENSTACK_FLAVOR='v1-standard-4'
export STACK_REGION_NAME='ca-ymq-1'
export AVAILABILITY_ZONE='ca-ymq-2'

PVE_BINDIR=$(dirname $PVERC)
echo "pve bindir: ${PVE_BINDIR}"

