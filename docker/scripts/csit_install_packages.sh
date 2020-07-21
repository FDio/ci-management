#! /bin/bash

set -euxo pipefail

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. $CIMAN_DOCKER_SCRIPTS/lib_csit.sh
. $CIMAN_DOCKER_SCRIPTS/lib_vpp.sh

must_be_called_by_docker_build

supported_os=""
case "$OS_NAME" in
    ubuntu-20.04) ;;
    centos-8) ;;
    debian-9) ;;
    *) supported_os="true"
       ;;
esac
if [ -z "$supported_os" ] ; then
    echo "CSIT is not supported on $OS_NAME. Skipping CSIT package install..."
    exit 0
fi

echo_log
echo_log "Starting  $(basename $0)"

do_git_config csit
for vpp_branch in ${VPP_BRANCHES[$OS_NAME]} ; do
  # Returns checked out branch in csit_branch
  csit_checkout_branch_for_vpp $vpp_branch

  # Install csit OS packages
  csit_install_packages $csit_branch

  # Install/cache python packages
  csit_pip_cache $csit_branch
done

echo_log -e "Completed $(basename $0)!\n\n=========="
