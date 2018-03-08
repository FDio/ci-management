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

##container server node detection
grep search /etc/resolv.conf  || true

if [ "${OS_ID}" == "ubuntu" ]; then
    dpkg-query -W -f='${binary:Package}\t${Version}\n' || true
    pip list || true
elif [ "${OS_ID}" == "centos" ]; then
    yum list installed || true
    pip list || true
elif [ "${OS_ID}" == "opensuse" ]; then
    yum list installed || true
    pip list || true
fi
