#!/bin/bash


ubuntu_systems() {


}

deb_probe_modules() {
    for mod in "$@"
    do
	modprobe ${mod}
    done
}

deb_enable_modules() {
    for mod in "$@"
    do
	echo ${mod} >> /etc/modules
    done
}

deb_aptconf_batchconf() {
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
}

deb_sync_minor() {
    # Standard update + upgrade dance
    apt-get update
    apt-get upgrade
    apt-get dist-upgrade
}

deb_correct_shell() {
    # Fix the silly notion that /bin/sh should point to dash by pointing it to bash
    update-alternatives --install /bin/sh sh /bin/bash 100
}

deb_flush() {
    apt-get autoremove
    apt-get clean
}

deb_install_pkgs() {
    LSB_PATH=$(which lsb_release)

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
	# Install plymouth label and themes to get rid of initrd warnings / errors
        PACKAGES="$PACKAGES plymouth-themes plymouth-label default-jdk-headless"
    fi

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

}

deb_enable_hugepages() {
    # Setup for hugepages using sysctl so it persists across reboots
    sysctl -w vm.nr_hugepages=1024

    mkdir -p /mnt/huge
    echo "hugetlbfs       /mnt/huge  hugetlbfs       defaults        0 0" >> /etc/fstab
}

deb_mount_hugepages() {
    mount /mnt/huge
}

deb_reup_certs() {
    # update CA certificates
    update-ca-certificates -f
}

rh_install_pkgs() {
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
