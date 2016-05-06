#!/bin/bash

deb_enable_serial_console() {
# enable grub and login on serial console

    echo <<EOF>> /etc/default/grub
GRUB_TERMINAL=serial
GRUB_SERIAL_COMMAND="serial --speed=38400 --unit=0 --word=8 --parity=no --stop=1"
EOF
    update-grub
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
    echo '---> Updating OS'
    # Standard update + upgrade dance
    apt-get -qq update
    apt-get -qq upgrade
    apt-get -qq dist-upgrade
}

deb_correct_shell() {
    echo '---> Correcting system shell'
    # Fix the silly notion that /bin/sh should point to dash by pointing it to bash
    update-alternatives --install /bin/sh sh /bin/bash 100
}

deb_flush() {
    echo '---> Flushing extra packages and package cache'
    apt-get -qq autoremove
    apt-get -qq clean
}

deb_add_ppa() {
    echo "---> Adding '$1' PPA"
    apt-get -qq install software-properties-common
    apt-add-repository -y $1
    apt-get -qq update
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
        DIST=$(echo "${ISSUE_TXT}" | awk '{print $1}')
        if [ "$DIST" = "Ubuntu" ]
        then
            VERSION=$(echo "${ISSUE_TXT}" | awk '{print $2}' | sed -e 's/^(\d+\.\d+)(\.\d+)?$/\1/')
        elif [ "$DIST" = "Debian" ]
        then
            VERSION=$(echo "${ISSUE_TXT}" | awk '{print $3}')
        else
            echo "Unrecognized distribution: ${DIST}"
        fi
    fi

    echo "---> Detected [${DIST} v${VERSION} (${CODENAME})]"

    PACKAGES="" # initialize PACKAGES
    if [ "$VERSION" = '14.04' ]
    then
        # openjdk-8-jdk is not available in 14.04 repos by default
	deb_add_ppa ppa:openjdk-r/ppa

        # Install OpenJDK v8 and v7
        PACKAGES="$PACKAGES openjdk-8-jdk-headless openjdk-7-jdk"
    else
        # Install default jdk
        PACKAGES="$PACKAGES default-jdk-headless"

	# Install plymouth label and themes to get rid of initrd warnings / errors
	apt-get -qq install plymouth-themes plymouth-label
    fi

    # Install build tools - should match vpp/Makefile DEB_DEPENDS variable
    PACKAGES="$PACKAGES curl build-essential autoconf automake bison libssl-dev ccache"
    PACKAGES="$PACKAGES debhelper dkms git libtool libganglia1-dev libapr1-dev dh-systemd"
    PACKAGES="$PACKAGES libconfuse-dev git-review exuberant-ctags cscope"


    # Install interface manipulation tools, editor, debugger and lsb
    PACKAGES="$PACKAGES iproute2 bridge-utils vim gdb lsb-release"

    # Install latest kernel and uio
    PACKAGES="$PACKAGES linux-image-extra-virtual linux-headers-virtual"

    # $$$ comment out for the moment
    # PACKAGES="$PACKAGES maven3"

    # Install virtualenv for test execution
    PACKAGES="$PACKAGES python-virtualenv python-pip python-dev"

    echo '---> Installing packages'
    # disable double quoting check
    # shellcheck disable=SC2086
    apt-get -qq install ${PACKAGES}

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
    echo '---> Forcing CA certificate update'
    update-ca-certificates -f
}

rh_clean_pkgs() {
    echo '---> Cleaning caches'
    yum clean all -q
}

rh_update_pkgs() {
    echo '---> Updating OS'
    yum upgrade -q -y
}

rh_install_pkgs() {
    echo '---> Installing tools'

    # Install build tools
    yum install -q -y @development redhat-lsb glibc-static java-1.8.0-openjdk-devel yum-utils \
                      openssl-devel apr-devel

    # Install python development
    yum search python34-devel 2>&1 | grep -q 'No matches'
    if [ $? -eq 0 ]
    then
	echo '---> Installing python-devel'
        yum install -q -y python-devel
    else
	echo '---> Installing python34-devel'
        yum install -q -y python34-devel
    fi

    echo '---> Configuring EPEL'
    # Install EPEL
    yum install -q -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

    # Install components to build Ganglia modules
    yum install -q -y --enablerepo=epel {libconfuse,ganglia}-devel mock

    # Install debuginfo packages
    debuginfo-install -q -y glibc-2.17-106.el7_2.4.x86_64 openssl-libs-1.0.1e-51.el7_2.4.x86_64 zlib-1.2.7-15.el7.x86_64
}
