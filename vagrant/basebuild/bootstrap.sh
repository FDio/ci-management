#!/bin/bash

# die on errors
set -e

# pull in bootstrap functions
. /vagrant/lib/bootstrap-functions.sh

echo "---> Attempting to detect OS"
# OS selector
if [ -f /usr/bin/yum ]
then
    echo "---> RH type system detected"
    rh_clean_pkgs
    rh_update_pkgs
    rh_install_pkgs

    rpm -V apr-devel
    if [ $? != 0 ]; then exec 1>&-;exec 2>&-exit 1; fi
    rpm -V ganglia-devel
    if [ $? != 0 ]; then exec 1>&-;exec 2>&-exit 1; fi
    rpm -V libconfuse-devel
    if [ $? != 0 ]; then exec 1>&-;exec 2>&-exit 1; fi

elif [ -f /usr/bin/apt-get ]
then
    echo "---> Debian type system detected"
    export DEBIAN_FRONTEND=noninteractive

    deb_aptconf_batchconf
    deb_sync_minor
    deb_correct_shell
    deb_install_pkgs
    deb_flush
    deb_reup_certs

    # It is not necessary to load uio module during bootstrap phase

    # deb_probe_modules uio_pci_generic

    # Make sure uio loads at boot time
    deb_enable_modules 'uio_pci_generic'

    deb_enable_hugepages

    # It is not necessary to mount hugepages during bootstrap phase

    # deb_mount_hugepages
fi

echo "bootstrap process (PID=$$) complete."

exit 0
