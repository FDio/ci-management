#!/bin/bash -x

# die on errors
set -e

# Redirect stdout ( 1> ) and stderr ( 2> ) into named pipes ( >() ) running "tee"
exec 1> >(tee -i /tmp/bootstrap-out.log)
exec 2> >(tee -i /tmp/bootstrap-err.log)

. bootstrap-functions.sh

echo "---> Attempting to detect OS"
# OS selector
if [ -f /usr/bin/yum ]
then
    OS='RH'
else
    OS='UBUNTU'
fi

case "$OS" in
    RH)
        echo "---> RH type system detected"
	rh_install_pkgs
    ;;
    UBUNTU)
        echo "---> Ubuntu system detected"
	export DEBIAN_FRONTEND=noninteractive

	deb_aptconf_batchconf
	deb_sync_minor
	deb_correct_shell
	deb_install_pkgs
	deb_flush
	deb_reup_certs

	# It is not necessary to load the uio kernel module during the bootstrap phase
	# deb_probe_modules uio_pci_generic

	# Make sure uio loads at boot time
	deb_enable_modules 'uio_pci_generic'

	deb_enable_hugepages
	# It is not necessary to mount the hugepages mount during the bootstrap phase
	# deb_mount_hugepages

    ;;
    *)
        echo "---> Unknown operating system"
    ;;
esac

echo "bootstrap process (PID=$$) complete."

exec 1>&- # close STDOUT
exec 2>&- # close STDERR

exit 0
