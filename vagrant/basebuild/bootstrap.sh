#!/bin/bash -x

# die on errors
set -e

# Redirect stdout ( 1> ) and stderr ( 2> ) into named pipes ( >() ) running "tee"
exec 1> >(tee -i /tmp/bootstrap-out.log)
exec 2> >(tee -i /tmp/bootstrap-err.log)

function clean_up {

    # Perform program exit housekeeping
    exec 1>&- # close STDOUT
    exec 2>&- # close STDERR

    exit
}

trap clean_up SIGHUP SIGINT SIGTERM


# record the bootstrap.sh checksum
shasum $0 > /etc/bootstrap.sha1

. bootstrap-functions.sh

echo "---> Attempting to detect OS"
# OS selector
if [ -f /usr/bin/yum ]
then
    echo "---> RH type system detected"
    rh_install_pkgs

    rpm -V apr-devel
    if [ if [ $? != 0 ]; then exec 1>&-;exec 2>&-exit 1; fi ]
    rpm -V ganglia-devel
    if [ if [ $? != 0 ]; then exec 1>&-;exec 2>&-exit 1; fi ]
    rpm -V libconfuse-devel
    if [ if [ $? != 0 ]; then exec 1>&-;exec 2>&-exit 1; fi ]

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
