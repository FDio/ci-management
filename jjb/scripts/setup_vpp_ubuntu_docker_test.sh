#!/bin/bash
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
set -e -o pipefail

OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')

if ! [ -z ${DOCKER_TEST} ] ; then
		mount -o remount /dev/shm -o size=512M || true
        echo "/dev/shm remounted"
fi

if [ "${OS_ID}" == "ubuntu" ]; then
    dpkg-query -W -f='${binary:Package}\t${Version}\n'
    pip list
elif [ "${OS_ID}" == "centos" ]; then
    yum list installed
    pip list
elif [ "${OS_ID}" == "opensuse" ]; then
    yum list installed
    pip list
fi
if [ "x${IS_CSIT_VPP_JOB}" == "xTrue" ]; then
	(cd dpdk ; apt-get download vpp-dpdk-dkms > /dev/null 2>&1) || true
    ls -l dpdk/*.deb || true
    echo "csit vpp-dpdk-dkms package download"
fi     