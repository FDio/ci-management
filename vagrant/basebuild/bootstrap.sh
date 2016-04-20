
ubuntu_systems() {
    # Standard update + upgrade dance
    apt-get update
    apt-get upgrade -y

    # Fix the silly notion that /bin/sh should point to dash by pointing it to bash

    sudo update-alternatives --install /bin/sh sh /bin/bash 100

    # Install build tools
    apt-get install -y build-essential autoconf automake bison libssl-dev ccache libtool git dkms debhelper libganglia1-dev libapr1-dev libconfuse-dev dh-systemd

    # Install other stuff
    apt-get install -y --force-yes bridge-utils vim gdb iproute2

    # Install debian packaging tools
    apt-get install -y debhelper dkms

    # Install uio
    apt-get install -y linux-image-extra-`uname -r`

    # Install jdk and maven
    apt-get install -y openjdk-7-jdk
    # $$$ comment out for the moment
    # apt-get install -y --force-yes maven3

    # Load the uio kernel module
    modprobe uio_pci_generic

    # Make sure uio loads at boot time
    echo uio_pci_generic >> /etc/modules

    # Setup for hugepages using upstart so it persists across reboots
    sysctl -w vm.nr_hugepages=1024
    mkdir -p /mnt/huge
    echo "hugetlbfs       /mnt/huge  hugetlbfs       defaults        0 0" >> /etc/fstab
    mount /mnt/huge

    # Install virtualenv for test execution
    apt-get install -y --force-yes python-virtualenv python-pip python-dev python3-dev
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
