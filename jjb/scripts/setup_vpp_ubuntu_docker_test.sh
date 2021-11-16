#!/bin/bash

##############################################################################
# Copyright (c) 2021 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

echo "---> jjb/scripts/setup_vpp_ubuntu_docker_test.sh"

set -e -o pipefail

OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')

if [ -n ${DOCKER_TEST} ] ; then
        # for 4 cores:
        # framework.VppTestCase.MIN_REQ_SHM + (num_cores * framework.VppTestCase.SHM_PER_PROCESS)
        # 1073741824 == 1024M (1073741824 >> 20)
        MEM=1024M
        if [[ ${MAKE_PARALLEL_JOBS} == '16' ]]
        then
            # arm build are running with 16 cores, empirical evidence shows
            # that 2048M is enough
            MEM=2048M
        fi
	sudo mount -o remount /dev/shm -o size=${MEM} || true
        echo "/dev/shm remounted with size='${MEM}'"
fi
