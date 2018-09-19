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
    echo "************************************************************************"
    echo "pip list:"
    pip list || true
    echo "************************************************************************"
    echo "Contents of /var/cache/vpp/python/virtualenv/lib/python2.7/site-packages:"
    ls -lth /var/cache/vpp/python/virtualenv/lib/python2.7/site-packages || true
    echo "************************************************************************"
    echo "Contents of br Downloads:"
    ls -lth /w/Downloads || true
    echo "************************************************************************"
    echo "Contents of /w/dpdk for test folks:"
    echo "************************************************************************"
    ls -lth /w/dpdk || true
elif [ "${OS_ID}" == "centos" ]; then
    yum list installed || true
    pip list || true
elif [ "${OS_ID}" == "opensuse" ]; then
    yum list installed || true
    pip list || true
fi

##This will remove any previously installed dpdk for old branch builds

if [ "${GERRIT_BRANCH}" != "master" ]; then
    if [ "${OS_ID}" == "ubuntu" ]; then
        apt-get -y remove vpp-dpdk-dev || true
        apt-get -y remove vpp-dpdk-dkms || true
        apt-get -y remove vpp-dev-contrib || true
    elif [ "${OS_ID}" == "centos" ]; then
        yum -y erase vpp-dpdk-devel || true
        yum -y erase vpp-dev-contrib || true
        yum clean all || true
    elif [ "${OS_ID}" == "opensuse" ]; then
        yum -y erase vpp-dpdk-devel || true
        yum -y erase vpp-dev-contrib || true
    fi
fi
