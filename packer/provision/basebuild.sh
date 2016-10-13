#!/bin/bash

# vim: ts=4 sw=4 sts=4 et tw=72 :

rh_systems() {

    # Install build tools
    yum install -y @development redhat-lsb glibc-static java-1.8.0-openjdk-devel yum-utils \
    openssl-devel apr-devel indent
    
    # Install python dependencies
    yum install -y python-{devel,virtualenv,setuptools,pip}

    # Build dependencies for Python packages
    yum install -y openssl-devel mysql-devel gcc

    #Install Documentation packages
    DOC_PKGS="doxygen graphviz pyparsing python-jinja2"
    yum install -y install ${DOC_PKGS}

    #Install components to build Ganglia modules
    yum install -y --enablerepo=epel {libconfuse,ganglia}-devel mock

    #Install module for VPP project
    echo uio_pci_generic >> /etc/modules

    #Install debuginfo packages
    debuginfo-install -y glibc-2.17-106.el7_2.4.x86_64 openssl-libs-1.0.1e-51.el7_2.4.x86_64 zlib-1.2.7-15.el7.x86_64

    # Packer builds happen from the centos flavor images
    PACKERDIR=$(mktemp -d)
    # disable double quote checking
    # shellcheck disable=SC2086
    cd $PACKERDIR
    wget https://releases.hashicorp.com/packer/0.10.1/packer_0.10.1_linux_amd64.zip
    unzip packer_0.10.1_linux_amd64.zip -d /usr/local/bin/
    # rename packer to avoid conflicts with cracklib
    mv /usr/local/bin/packer /usr/local/bin/packer.io

    # cleanup from the installation
    # disable double quote checking
    # shellcheck disable=SC2086
    rm -rf $PACKERDIR
    # cleanup from previous install process
    if [ -d /tmp/packer ]
    then
        rm -rf /tmp/packer
    fi
}

ubuntu_systems() {
    # Install python dependencies
    apt install -y python-{dev,virtualenv,setuptools,pip}

    # Build dependencies for Python packages
    apt install -y libssl-dev libmysqlclient-dev gcc

    # ADD A VAR FOR THIS apt-get --no-install-recommends --no-install-suggests

    # Install the correct version of toolchain packages
    echo "---> Installing latest toolchain packages from PPA $(date +'%Y%m%dT%H%M%S')"

    #Install PPA packages
    echo "---> Adding '$1' PPA $(date +'%Y%m%dT%H%M%S')"
    dpkg -l software-properties-common > /dev/null 2>&1 || software-properties-common

    listfile=$(perl -e "print(q{$1} =~ m{^ppa:(.+)/ppa})")-ppa-${CODENAME}.list
      if [ ! -f /etc/apt/sources.list.d/${listfile} ]
      then
        do_retry sudo apt-add-repository -y $1
      fi

    #Retry to prevent timeout failure
    echo "---> Updating package index $(date +'%Y%m%dT%H%M%S')"
    do_retry sudo apt-get update

    echo "<--- Updating package index $(date +'%Y%m%dT%H%M%S')"

    echo "<--- Adding '$1' PPA $(date +'%Y%m%dT%H%M%S')"

    #Install GCC packages
    GCC_VERSION=5
    GCC_PKGS="cpp-${GCC_VERSION} gcc-${GCC_VERSION} g++-${GCC_VERSION}"

    #Retry to prevent timeout failure
    echo "---> Updating package index $(date +'%Y%m%dT%H%M%S')"
    do_retry sudo apt-get update

    echo "<--- Updating package index $(date +'%Y%m%dT%H%M%S')"

    echo "<--- Adding '$1' PPA $(date +'%Y%m%dT%H%M%S')"

    apt install -y ${GCC_PKGS}

      for BIN in cpp gcc g++
        do
          sudo update-alternatives --remove-all ${BIN} > /dev/null 2>&1 || echo -n ""
          sudo update-alternatives --install /usr/bin/${BIN} ${BIN} /usr/bin/${BIN}-${GCC_VERSION} 50 > /dev/null 2>&1
        done

        echo "<--- Installing latest toolchain packages from PPA $(date +'%Y%m%dT%H%M%S')"

      #Install VPP packages to shorten build times
      echo "---> Installing VPP DEB_DEPENDS packages $(date +'%Y%m%dT%H%M%S')"
      apt install -y \
        curl build-essential autoconf automake bison libssl-dev ccache \
        debhelper dkms git libtool libganglia1-dev libapr1-dev dh-systemd \
        libconfuse-dev git-review exuberant-ctags cscope \

      echo "<--- Installing VPP DEB_DEPENDS packages $(date +'%Y%m%dT%H%M%S')"

      # Install latest kernel and uio
      echo "---> Installing kernel image and header packages  $(date +'%Y%m%dT%H%M%S')"
      apt install -y linux-image-extra-virtual linux-headers-virtual

      echo "<--- Installing kernel image and header packages  $(date +'%Y%m%dT%H%M%S')"

      #Install deb_dpdk packages to shorten build times
      echo "---> Installing deb_dpdk packages $(date +'%Y%m%dT%H%M%S')"
      apt install -y dpkg-dev devscripts pristine-tar dh-python \
        inkscape libcap-dev libpcap-dev libxen-dev libxenstore3.0 \
        python-sphinx python-sphinx-rtd-theme \
        texlive-fonts-recommended tex-common texlive-base \
        texlive-binaries texlive-pictures texlive-latex-recommended \
        preview-latex-style texlive-latex-extra

      echo "<--- Installing deb_dpdk packages $(date +'%Y%m%dT%H%M%S')"

      #Clean up packages for a smaller image
      apt-get update

      #Updating CA certificates
      echo "---> Forcing CA certificate update $(date +'%Y%m%dT%H%M%S')"
      sudo update-ca-certificates -f > /dev/null 2>&1

      echo "<--- Forcing CA certificate update $(date +'%Y%m%dT%H%M%S')"
}

all_systems() {
    echo 'Configure keep alive to prevent timeout during testing'
    local SSH_CFG=/etc/ssh/ssh_config
    echo "TCPKeepAlive        true" | sudo tee -a ${SSH_CFG} >/dev/null 2>&1
    echo "ServerAliveCountMax 30"   | sudo tee -a ${SSH_CFG} >/dev/null 2>&1
    echo "ServerAliveInterval 10"   | sudo tee -a ${SSH_CFG} >/dev/null 2>&1

}

echo "---> Detecting OS"
ORIGIN=$(facter operatingsystem | tr '[:upper:]' '[:lower:]')

case "${ORIGIN}" in
    fedora|centos|redhat)
        echo "---> RH type system detected"
        rh_systems
    ;;
    ubuntu)
        echo "---> Ubuntu system detected"
        ubuntu_systems
    ;;
    *)
        echo "---> Unknown operating system"
    ;;
esac

# execute steps for all systems
all_systems
