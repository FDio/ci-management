#!/bin/bash

# vim: ts=4 sw=4 sts=4 et tw=72 :

rh_systems() {

    # RH Install build tools
    echo "---> Installing RH build tools $(date +'%Y%m%dT%H%M%S')"
    RH_TOOLS_PKGS="@development redhat-lsb glibc-static java-1.8.0-openjdk-devel yum-utils openssl-devel apr-devel indent"
    yum install -y ${RH_TOOLS_PKGS}

    # Memory leakage checks
    yum install -y valgrind

    # RH Install Python dependencies
    echo "---> Installing RH Python dependencies $(date +'%Y%m%dT%H%M%S')"
    RH_PYTHON_PKGS="python-devel python-virtualenv python-setuptools python-pip openssl-devel mysql-devel"
    yum install -y ${RH_PYTHON_PKGS}

    # RH Install Documentation packages
    echo "---> Installing RH documentation packages $(date +'%Y%m%dT%H%M%S')"
    RH_DOC_PKGS="doxygen graphviz python-pyparsing python-jinja2 asciidoc dblatex source-highlight python-sphinx"
    yum install -y install ${RH_DOC_PKGS}

    # RH Install GCC packages
    echo "---> Installing RH GCC packages $(date +'%Y%m%dT%H%M%S')"
    RH_GCC_PKGS="gcc c++ cmake"
    yum install -y ${RH_GCC_PKGS}

    # RH Install components to build Ganglia modules
    echo "---> Installing RH components $(date +'%Y%m%dT%H%M%S')"
    RH_GANGLIA_MODS="libconfuse-devel ganglia-devel mock"
    yum install -y --enablerepo=epel ${RH_GANGLIA_MODS}

    # RH Install module for VPP project
    echo uio_pci_generic >> /etc/modules

    # RH Install VPP packages to shorten build times
    echo "---> Installing VPP dependencies $(date +'%Y%m%dT%H%M%S')"
    RH_VPP_PKGS="curl build-essential autoconf automake bison libssl-dev ccache debhelper dkms git libtool libganglia1-dev libapr1-dev dh-systemd libconfuse-dev git-review exuberant-ctags cscope"
    yum install -y ${RH_VPP_PKGS}

    # RH Install TLDK dependencies
    RH_TLKD_PKGS="libpcap-dev_1.5.3-2_all.deb libpcap0.8-dev_1.5.3-2_amd64.deb"
    yum install -y ${RH_TLKD_PKGS}

    # RH Install debuginfo packages
    echo "---> Installing debug packages $(date +'%Y%m%dT%H%M%S')"
    RH_DEBUG_PKGS="glibc-2.17-106.el7_2.4.x86_64 openssl-libs-1.0.1e-51.el7_2.4.x86_64 zlib-1.2.7-15.el7.x86_64"
    debuginfo-install -y ${RH_DEBUG_PKGS}

    # RH Packer builds happen from the centos flavor images
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

    # DEB cloud packages
    echo "---> Installing cloud packages $(date +'%Y%m%dT%H%M%S')"
    CLOUD_PKGS="cloud-initramfs-dyn-netconf cloud-initramfs-growroot cloud-initramfs-rescuevol"
    apt install -y ${CLOUD_PKGS}

    # DEB Install Python dependencies
    echo "---> Installing Python dependencies $(date +'%Y%m%dT%H%M%S')"
    PYTHON_PKGS="python-dev python-virtualenv python-setuptools python-pip libssl-dev libmysqlclient-dev python2.7 python-docutils python-lxml python-numpy python-pil python-pygments python-roman python-sphinx python-talloc"
    apt install -y ${PYTHON_PKGS}

    # Memory leakage checks
    apt install -y valgrind

    # DEB Install Documentation packages
    echo "---> Installing documentation packages $(date +'%Y%m%dT%H%M%S')"
    DOC_PKGS="doxygen graphviz python-pyparsing python-jinja2 asciidoc dblatex source-highlight docutils-common docutils-doc"
    apt install -y ${DOC_PKGS}

    # DEB Install the correct version of toolchain packages
    echo "---> Installing latest toolchain packages from PPA $(date +'%Y%m%dT%H%M%S')"

    # DEB Install PPA packages
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

    # DEB Install GCC packages
    echo "---> Installing GCC packages $(date +'%Y%m%dT%H%M%S')"
    GCC_PKGS="cpp gcc g++ cmake lcov"
    apt install -y ${GCC_PKGS}

    # DEB Install VPP packages to shorten build times
    echo "---> Installing VPP DEB_DEPENDS packages $(date +'%Y%m%dT%H%M%S')"
    VPP_PKGS="curl build-essential autoconf automake bison libssl-dev ccache debhelper dkms git libtool libganglia1-dev libapr1-dev dh-systemd libconfuse-dev git-review exuberant-ctags cscope indent"
    apt install -y ${VPP_PKGS}

    # DEB Install latest kernel and uio
    echo "---> Installing kernel image and header packages $(date +'%Y%m%dT%H%M%S')"
    DEB_PKGS="linux-image-extra-virtual linux-headers-virtual linux-headers-`uname -r` linux-headers-3.13.0-96 linux-headers-3.13.0-96-generic linux-image-3.13.0-96-generic linux-image-extra-3.13.0-96-generic"
    apt install -y ${DEB_PKGS}

    #Configuring thirdparty Nexus repo
    echo "deb [trusted=yes] https://nexus.fd.io/content/repositories/thirdparty ./" > /etc/apt/sources.list.d/FD.io.thirdparty.list
    apt-get update

    # DEB Install deb_dpdk packages to shorten build times
    ###NOT INSTALLING libcap-dev libxenstore3.0 inkscape libpcap-dev
    echo "---> Installing deb_dpdk packages $(date +'%Y%m%dT%H%M%S')"
    DEB_DPDK_PKGS="lsb-release dpkg-dev devscripts pristine-tar dh-python inkscape libcap-dev libpcap0.8-dev libxen-dev libxenstore3.0 python-sphinx sphinx-rtd-theme python-sphinx-rtd-theme libpcap0.8-dev libstdc++5 scapy imagemagick imagemagick-common javascript-common libaspell15 ibatkmm-1.6-1 libcairomm-1.0-1 libdjvulibre-text libdjvulibre21 libfftw3-double3 libgd-gd2-perl libgfortran3 libglibmm-2.4-1c2a libgnomevfs2-extra libgsl0ldbl libgtkmm-2.4-1c2a libgtkspell0 libhunspell-1.3-0 libilmbase6 libjs-jquery libjs-modernizr libjs-sphinxdoc libjs-underscore liblapack3 libldb1 liblqr-1-0 libmagick++5 libmagickcore5 libmagickcore5 libmagickcore5-extra libmagickwand5 libnetpbm10 libopenexr6 libpangomm-1.4-1 libperl5.18 libpoppler-glib8 librsvg2-2 librsvg2-common libsmbclient libtalloc2 libtevent0 libwbclient0 libwebp5 libwebpmux1 libwmf-bin libwmf0.2-7 libwpd-0.9-9 libwpg-0.2-2 libwrap0 libxen-4.4 libxen-dev libyajl2 netpbm perlmagick plymouth libblas3 sphinx-common sphinx-doc sphinx-rtd-theme-common transfig"
    apt install -y ${DEB_DPDK_PKGS}

    TEXLIVE_PKGS="texlive-fonts-recommended tex-common texlive-base texlive-binaries texlive-pictures texlive-latex-recommended preview-latex-style texlive-latex-extra"
    apt install -y ${TEXLIVE_PKGS}
    echo "<--- Installing deb_dpdk packages $(date +'%Y%m%dT%H%M%S')"

    # DEB Manipulation tools, edits debugger, and LSB
    echo "---> Installing tools packages $(date +'%Y%m%dT%H%M%S')"
    TOOL_PKGS="iproute2 ethtool vlan bridge-utils vim gdb lsb-release emacs24-bin-common emacs24-common emacs24-common-non-dfsg emacsen-common emacs24-nox fonts-font-awesome fonts-lato aspell aspell-en dictionaries-common hunspell-en-us enchant libaspell15"
    apt install -y ${TOOL_PKGS}

    # DEB Clean up packages for a smaller image
    apt-get update

    # DEB Updating CA certificates
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
