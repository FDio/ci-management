#!/bin/bash -x

# die on errors
set -e

# Redirect stdout ( > ) and stderr ( 2> ) into named pipes ( >() ) running "tee"
exec > >(tee -i /tmp/bootstrap-out.log)
exec 2> >(tee -i /tmp/bootstrap-err.log)

ubuntu_systems() {

    VERSION=$(lsb_release -r | awk '{print $2}')

    export DEBIAN_FRONTEND=noninteractive
    cat <<EOF >> /etc/apt/apt.conf
APT {
  Get {
    Assume-Yes "true";
    allow-change-held-packages "true";
    allow-downgrades "true";
    allow-remove-essential "true";
  };
};

Dpkg::Options {
   "--force-confdef";
   "--force-confold";
};

EOF

    # Standard update + upgrade dance
    apt-get update
    apt-get upgrade
    apt-get dist-upgrade

    # Fix the silly notion that /bin/sh should point to dash by pointing it to bash

    update-alternatives --install /bin/sh sh /bin/bash 100

    # Install build tools
    PACKAGES="build-essential autoconf automake bison libssl-dev ccache libtool git dkms debhelper libganglia1-dev libapr1-dev libconfuse-dev"

    # Install interface manipulation tools, editor and debugger
    PACKAGES="$PACKAGES iproute2 bridge-utils vim gdb"

    # Install debian packaging tools
    PACKAGES="$PACKAGES debhelper dh-systemd dkms"

    # Install latest kernel and uio
    PACKAGES="$PACKAGES linux-image-extra-virtual"

    # Install plymouth labels and themes to get rid of initrd warnings / errors
    if [ $VERSION != '14.04' ]
    then
        PACKAGES="$PACKAGES plymouth-themes plymouth-label"
    fi

    # Install jdk and maven
    PACKAGES="$PACKAGES default-jdk"
    # $$$ comment out for the moment
    # PACKAGES="$PACKAGES maven3"

    # Install virtualenv for test execution
    PACKAGES="$PACKAGES python-virtualenv python-pip python-dev"

    apt-get install ${PACKAGES}
    apt-get autoremove
    apt-get clean

    # It is not necessary to load the uio kernel module during the bootstrap phase
#    modprobe uio_pci_generic

    # Make sure uio loads at boot time
    echo uio_pci_generic >> /etc/modules

    # Setup for hugepages using upstart so it persists across reboots
    sysctl -w vm.nr_hugepages=1024
    echo "vm.nr_hugepages=1024" >> /etc/sysctl.conf

    mkdir -p /mnt/huge
    echo "hugetlbfs       /mnt/huge  hugetlbfs       defaults        0 0" >> /etc/fstab
    mount /mnt/huge

}

rh_systems() {
    # Install build tools
    yum groupinstall 'Development Tools' -y
    yum install openssl-devel -y
    yum install glibc-static -y

    # Install jdk and maven
    yum install -y java-1.8.0-openjdk-devel

    # Install python development
    yum install -y python34-devel

    # Install EPEL
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

    # Install components to build Ganglia modules
    yum install -y apr-devel
    yum install -y --enablerepo=epel libconfuse-devel
    yum install -y --enablerepo=epel ganglia-devel
    yum install -y --enablerepo=epel mock
}

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
        rh_systems
    ;;
    UBUNTU)
        echo "---> Ubuntu system detected"
        ubuntu_systems
    ;;
    *)
        echo "---> Unknown operating system"
    ;;
esac

echo "bootstrap process (PID=$$) complete."

exit 0
