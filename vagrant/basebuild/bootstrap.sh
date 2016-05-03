#!/bin/bash -x

# die on errors
set -e

# Redirect stdout ( 1> ) and stderr ( 2> ) into named pipes ( >() ) running "tee"
exec 1> >(tee -i /tmp/bootstrap-out.log)
exec 2> >(tee -i /tmp/bootstrap-err.log)

ubuntu_systems() {

    LSB_PATH=$(which lsb_release)
    PACKAGES="" # initialize PACKAGES

    if [ $? == 0 ]
    then
        VERSION=$(lsb_release -r | awk '{print $2}')
        DIST=$(lsb_release -i | awk '{print $3}')
        CODENAME=$(lsb_release -c | awk '{print $2}')
    else
        ISSUE_TXT=$(head -1 /etc/issue)
        DIST=$(echo ${ISSUE_TXT} | awk '{print $1}')
        if [ "$DIST" = "Ubuntu" ]
        then
            VERSION=$(echo ${ISSUE_TXT} | awk '{print $2}' | sed -e 's/^(\d+\.\d+)(\.\d+)?$/\1/')
        elif [ "$DIST" = "Debian" ]
        then
            VERSION=$(echo ${ISSUE_TXT} | awk '{print $3}')
        else
            echo "Unrecognized distribution: ${DIST}"
        fi
    fi

    echo "Detected [${DIST} v${VERSION} (${CODENAME})]"

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

    # Install plymouth labels and themes to get rid of initrd warnings / errors
    if [ "$VERSION" = '14.04' ]
    then

        # openjdk-8-jdk is not available in 14.04 repos by default
        add-apt-repository ppa:openjdk-r/ppa

        # Install OpenJDK
        PACKAGES="$PACKAGES openjdk-8-jdk-headless"

        # Install Oracle's jdk version 8
#        apt-add-repository -y ppa:webupd8team/java
#        apt-get -qq update
#        echo "debconf shared/accepted-oracle-license-v1-1 select true
#              debconf shared/accepted-oracle-license-v1-1 seen true" | sudo debconf-set-selections
#        PACKAGES="$PACKAGES oracle-java8-installer"
    else
        # Install default jdk and plymouth packages
        PACKAGES="$PACKAGES plymouth-themes plymouth-label default-jdk-headless"
    fi


    # Standard update + upgrade dance
    apt-get update
    apt-get upgrade
    apt-get dist-upgrade

    # Fix the silly notion that /bin/sh should point to dash by pointing it to bash

    update-alternatives --install /bin/sh sh /bin/bash 100

    # Install build tools
    PACKAGES="$PACKAGES build-essential autoconf automake bison libssl-dev ccache libtool git dkms debhelper libganglia1-dev libapr1-dev libconfuse-dev"

    # Install interface manipulation tools, editor, debugger and lsb
    PACKAGES="$PACKAGES iproute2 bridge-utils vim gdb lsb-release"

    # Install debian packaging tools
    PACKAGES="$PACKAGES debhelper dh-systemd dkms"

    # Install latest kernel and uio
    PACKAGES="$PACKAGES linux-image-extra-virtual"

    # $$$ comment out for the moment
    # PACKAGES="$PACKAGES maven3"

    # Install virtualenv for test execution
    PACKAGES="$PACKAGES python-virtualenv python-pip python-dev"

    apt-get install ${PACKAGES}
    apt-get autoremove
    apt-get clean

    # update CA certificates
    update-ca-certificates -f

    # It is not necessary to load the uio kernel module during the bootstrap phase
#    modprobe uio_pci_generic

    # Make sure uio loads at boot time
    echo uio_pci_generic >> /etc/modules

    # Setup for hugepages using sysctl so it persists across reboots
    sysctl -w vm.nr_hugepages=1024

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
    yum search python34-devel 2>&1 | grep -q 'No matches'
    if [ $? -eq 0 ]
    then
        yum install -y python-devel
    else
        yum install -y python34-devel
    fi

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

exec 1>&- # close STDOUT
exec 2>&- # close STDERR

exit 0
