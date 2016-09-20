#!/bin/bash

do_setup() {
    echo "127.0.1.1 $(hostname) # temporary" >> /etc/hosts
}

do_mvn_install() {
    MAVEN_VERSION=3.3.9
    MAVEN_FILENAME=apache-maven-${MAVEN_VERSION}-bin.tar.gz
    MAVEN_HOME=/opt/apache/maven

    mkdir -p ${MAVEN_HOME}
    tar -C ${MAVEN_HOME} --strip-components 1 -xzf /vagrant/${MAVEN_FILENAME}
}


do_cleanup() {
    perl -i -ne 'print unless /^127.0.1.1.*# temporary$/' /etc/hosts
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

quiet "2";

EOF
}

deb_sync_minor() {
    echo '---> Updating OS'
    # Standard update + upgrade dance
    apt-get update
    apt-get upgrade
    apt-get dist-upgrade
}

deb_correct_shell() {
    echo '---> Correcting system shell'
    # Fix the silly notion that /bin/sh should point to dash by pointing it to bash
    update-alternatives --install /bin/sh sh /bin/bash 100
}

deb_flush() {
    echo '---> Flushing extra packages and package cache'
    apt-get autoremove
    apt-get clean
}

deb_add_repo() {
    echo "---> Adding '$1' repo"
    echo "$2" > "/etc/apt/sources.list.d/$1.list"
}

deb_add_ppa() {
    echo "---> Adding '$1' PPA"
    apt-get install software-properties-common
    ATTEMPT=0
    while [ ${ATTEMPT} -le 4 ]
    do
        FAIL=0
        apt-add-repository -y $1 || FAIL=1
        if [ ${FAIL} -eq 0 ]
        then
            break
        fi
        ATTEMPT=$(expr $ATTEMPT + 1)
    done
    apt-get update
}

deb_install_pkgs() {
    apt-get install lsb-release
    LSB_PATH=$(which lsb_release)

    VERSION=$(lsb_release -r | awk '{print $2}')
    DIST=$(lsb_release -i | awk '{print $3}')
    CODENAME=$(lsb_release -c | awk '{print $2}')

    echo "---> Detected [${DIST} v${VERSION} (${CODENAME})]"

    # initialize PACKAGES
    PACKAGES="cloud-initramfs-dyn-netconf cloud-initramfs-growroot
              cloud-initramfs-rescuevol"

    if [ "$VERSION" = '14.04' ]
    then
        # openjdk-8-jdk is not available in 14.04 repos by default
        deb_add_ppa ppa:openjdk-r/ppa

        # python-sphinx-rtd-theme is not available in 14.04 repos by default
        deb_add_repo FD.io.thirdparty "deb [trusted=yes] https://nexus.fd.io/content/repositories/thirdparty ./"

        # Install OpenJDK v8 *and* v7 on Trusty
        PACKAGES="$PACKAGES openjdk-8-jdk-headless openjdk-7-jdk emacs24-nox"
    elif [ "$VERSION" = '16.04' ]
    then
        # Install default jdk (v8 on this platform)
        PACKAGES="$PACKAGES default-jdk-headless emacs-nox"

          # plymouth-label and plymouth-themes are required to get rid of
        # initrd warnings / errors on 16.04
          apt-get install plymouth-themes plymouth-label
    fi

    # Build tools - should match vpp/Makefile DEB_DEPENDS variable
    PACKAGES="$PACKAGES curl build-essential autoconf automake bison libssl-dev
              ccache debhelper dkms git libtool libganglia1-dev
              libapr1-dev dh-systemd libconfuse-dev git-review
              exuberant-ctags cscope indent debhelper dh-python
              dh-systemd dkms doxygen graphviz inkscape libcap-dev
              libpcap-dev libxen-dev libxenstore3.0 python
              python-sphinx python-sphinx-rtd-theme devscripts
              texlive-fonts-recommended texlive-latex-extra"

    # Interface manipulation tools, editors, debugger and lsb
    PACKAGES="$PACKAGES iproute2 ethtool vlan bridge-utils
              vim gdb lsb-release"

    # Install latest kernel and uio
    PACKAGES="$PACKAGES linux-image-extra-virtual linux-headers-virtual"

    # $$$ comment out for the moment
    # PACKAGES="$PACKAGES maven3"

    # Install virtualenv for test execution
    PACKAGES="$PACKAGES python-virtualenv python-pip python-dev"

    # Install to allow the vpp-docs job to zip up docs to push them
    PACKAGES="$PACKAGES zip"

    echo '---> Installing packages'
    # disable double quoting check
    # shellcheck disable=SC2086
    apt-get install ${PACKAGES}

    # Specify documentation packages
    DOC_PACKAGES="doxygen graphviz python-pyparsing"
    apt-get install ${DOC_PACKAGES}
}

deb_enable_hugepages() {
    # Setup for hugepages using sysctl so it persists across reboots
    AVP="vm.nr_hugepages=1024"
    sysctl -w ${AVP}
    echo "${AVP}" >> /etc/sysctl.conf

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

deb_remove_pkgs() {
    echo '---> Removing unattended-upgrades packge to avoid it locking /var/lib/dpkg/lock'
    apt-get remove unattended-upgrades
}

deb_disable_apt_systemd_daily() {
    echo '---> Stopping and disabling apt.systemd.daily to avoid it locking /var/lib/dpkg/lock'
    if [ -f /usr/bin/systemctl ]
    then
        systemctl stop apt.systemd.daily
        systemctl disable apt.systemd.daily
    else
        /etc/init.d/unattended-upgrades stop
        update-rc.d -f unattended-upgrades remove
    fi
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
                      openssl-devel apr-devel indent

    # Specify documentation packages
    DOC_PACKAGES="doxygen graphviz"
    yum install -q -y install ${DOC_PACKAGES}

    # Install python development
    OUTPUT=$(yum search python34-devel 2>&1 | grep 'No matches')
    if [ -z "$OUTPUT" ]
    then
    echo '---> Installing python34-devel'
        yum install -q -y python34-devel
    else
    echo '---> Installing python-devel'
        yum install -q -y python-devel
    fi

    echo '---> Configuring EPEL'
    # Install EPEL
    OUTPUT=$(rpm -qa epel-release)
    if [ -z "$OUTPUT" ]
    then
        yum install -q -y /vagrant/epel-release-latest-7.noarch.rpm
    fi

    # Install components to build Ganglia modules
    yum install -q -y --enablerepo=epel {libconfuse,ganglia}-devel mock

    # Install debuginfo packages
    debuginfo-install -q -y glibc-2.17-106.el7_2.4.x86_64 openssl-libs-1.0.1e-51.el7_2.4.x86_64 zlib-1.2.7-15.el7.x86_64
}
