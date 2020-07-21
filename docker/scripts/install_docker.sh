#! /bin/bash

set -euxo pipefail

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. $CIMAN_DOCKER_SCRIPTS/lib_apt.sh
. $CIMAN_DOCKER_SCRIPTS/lib_yum.sh
. $CIMAN_DOCKER_SCRIPTS/lib_dnf.sh

must_be_called_by_docker_build

echo_log
echo_log "Starting  $(basename $0)"

case "$DOCKERFILE_FROM" in
  *ubuntu*)
    write_apt_ubuntu_docker_gpg_keyfile
    apt_install_docker_os_package_dependancies
    apt_install_docker $DOCKER_APT_UBUNTU_DOCKER_GPGFILE
    ;;
  *debian*)
    write_apt_debian_docker_gpg_keyfile
    apt_install_docker_os_package_dependancies
    apt_install_docker $DOCKER_APT_DEBIAN_DOCKER_GPGFILE
    ;;
  *centos:7)
    yum_install_docker_os_package_dependancies
    yum_install_docker
    ;;
  *centos:8)
    dnf_install_docker_os_package_dependancies
    dnf_install_docker
    ;;
esac
