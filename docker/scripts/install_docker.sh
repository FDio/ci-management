#! /bin/bash

# Copyright (c) 2020 Cisco and/or its affiliates.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euxo pipefail

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. $CIMAN_DOCKER_SCRIPTS/lib_apt.sh
. $CIMAN_DOCKER_SCRIPTS/lib_yum.sh
. $CIMAN_DOCKER_SCRIPTS/lib_dnf.sh

must_be_run_as_root
must_be_run_in_docker_build

echo_log
echo_log "Starting  $(basename $0)"

case "$DOCKERFILE_FROM" in
    *ubuntu*)
        write_apt_ubuntu_docker_gpg_keyfile
        apt_install_docker_os_package_dependancies
        apt_install_docker $DOCKER_APT_UBUNTU_DOCKER_GPGFILE ;;
    *debian*)
        write_apt_debian_docker_gpg_keyfile
        apt_install_docker_os_package_dependancies
        apt_install_docker $DOCKER_APT_DEBIAN_DOCKER_GPGFILE ;;
    *centos:7)
        yum_install_docker_os_package_dependancies
        yum_install_docker ;;
    *centos:8)
        dnf_install_docker_os_package_dependancies
        dnf_install_docker ;;
esac

echo_log -e "Completed $(basename $0)!\n\n=========="
