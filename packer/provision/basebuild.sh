#!/bin/bash

# vim: ts=4 sw=4 sts=4 et tw=72 :

rh_systems() {

    # RH Install build tools
    echo "---> Installing RH build tools $(date +'%Y%m%dT%H%M%S')"
    RH_TOOLS_PKGS="@development redhat-lsb glibc-static \
      java-1.8.0-openjdk-devel yum-utils openssl-devel apr-devel indent rpm"
    yum install -y ${RH_TOOLS_PKGS}

    # Memory leakage checks
    yum install -y valgrind

    # RH Install Python dependencies
    ###REMOVED mysql-devel
    echo "---> Installing RH Python dependencies $(date +'%Y%m%dT%H%M%S')"
    RH_PYTHON_PKGS="python-devel python-virtualenv python-setuptools \
      python-pip kernel-devel epel-rpm-macros"
    pip install --upgrade pip
    yum install -y ${RH_PYTHON_PKGS}
    pip install pypcap

    # RH Install Documentation packages
    ###Removed python-pyparsing
    echo "---> Installing RH documentation packages $(date +'%Y%m%dT%H%M%S')"
    RH_DOC_PKGS="doxygen graphviz python-jinja2 asciidoc \
      dblatex source-highlight python-sphinx libxml2 libffi-devel python-cffi"
    yum install -y install ${RH_DOC_PKGS}

    # RH Install GCC packages
    echo "---> Installing RH GCC packages $(date +'%Y%m%dT%H%M%S')"
    RH_GCC_PKGS="cpp gcc c++ cmake make"
    yum install -y ${RH_GCC_PKGS}

    # RH Install components to build Ganglia modules
    echo "---> Installing RH components $(date +'%Y%m%dT%H%M%S')"
    RH_GANGLIA_MODS="libconfuse-devel ganglia-devel mock"
    yum install -y --enablerepo=epel ${RH_GANGLIA_MODS}

    # RH Install module for VPP project
    echo uio_pci_generic >> /etc/modules

    # RH Install VPP packages to shorten build times
    echo "---> Installing VPP dependencies $(date +'%Y%m%dT%H%M%S')"
    RH_VPP_PKGS="curl autoconf automake bison ccache dkms git libtool \
      libconfuse-dev git-review cscope"
    yum install -y ${RH_VPP_PKGS}

    yum groupinstall "Development Tools"
    # RH Install TLDK dependencies
    RH_TLKD_PKGS="libpcap-devel libcap-devel scapy"
    yum install -y ${RH_TLKD_PKGS}

    # RH Install Puppet packages
    PUPPET_PKGS="libxml2-devel libxslt-devel ruby-devel zlib-devel"
    yum install -y ${PUPPET_PKGS}

    # RH Install debuginfo packages
    #echo "---> Installing debug packages $(date +'%Y%m%dT%H%M%S')"
    #RH_DEBUG_PKGS="glibc openssl-libs zlib"
    #debuginfo-install -y ${RH_DEBUG_PKGS}

    # # RH Packer builds happen from the centos flavor images
    # PACKERDIR=$(mktemp -d)
    # # disable double quote checking
    # # shellcheck disable=SC2086
    # cd $PACKERDIR
    # wget https://releases.hashicorp.com/packer/0.10.1/packer_0.10.1_linux_amd64.zip
    # unzip packer_0.10.1_linux_amd64.zip -d /usr/local/bin/
    # # rename packer to avoid conflicts with cracklib
    # mv /usr/local/bin/packer /usr/local/bin/packer.io

    # # cleanup from the installation
    # # disable double quote checking
    # # shellcheck disable=SC2086
    # rm -rf $PACKERDIR
    # # cleanup from previous install process
    # if [ -d /tmp/packer ]
    # then
    #     rm -rf /tmp/packer
    # fi
}

ubuntu_systems() {

    # DEB add Toolchain repo
    sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test

    #Configuring thirdparty Nexus repo
    echo "deb [trusted=yes] https://nexus.fd.io/content/repositories/thirdparty ./" > /etc/apt/sources.list.d/FD.io.thirdparty.list

    # DEB Install PPA packages
    echo "---> Adding '$1' PPA $(date +'%Y%m%dT%H%M%S')"
    dpkg -l software-properties-common > /dev/null 2>&1 || software-properties-common

    listfile=$(perl -e "print(q{$1} =~ m{^ppa:(.+)/ppa})")-ppa-${CODENAME}.list
      if [ ! -f /etc/apt/sources.list.d/${listfile} ]
      then
        do_retry sudo apt-add-repository -y $1
      fi

    apt-get update

    # DEB cloud packages
    echo "---> Installing cloud packages $(date +'%Y%m%dT%H%M%S')"
    CLOUD_PKGS="cloud-initramfs-dyn-netconf cloud-initramfs-growroot \
      cloud-initramfs-rescuevol"
    apt install -y ${CLOUD_PKGS}

    # DEB Install Python dependencies
    echo "---> Installing Python dependencies $(date +'%Y%m%dT%H%M%S')"
    PYTHON_PKGS="python-all python-dev python-virtualenv python-setuptools \
      python-pip libssl-dev libmysqlclient-dev python2.7 libffi-dev \
      python-cffi"
    apt install -y ${PYTHON_PKGS}

    # Memory leakage checks
    apt install -y valgrind

    # DEB Install Documentation packages
    echo "---> Installing documentation packages $(date +'%Y%m%dT%H%M%S')"
    DOC_PKGS="doxygen graphviz python-pyparsing python-jinja2 asciidoc \
      dblatex source-highlight"
    apt install -y ${DOC_PKGS}

    # DEB Install the correct version of toolchain packages
    echo "---> Installing latest toolchain packages from PPA $(date +'%Y%m%dT%H%M%S')"

    #Retry to prevent timeout failure
    #echo "---> Updating package index $(date +'%Y%m%dT%H%M%S')"
    #do_retry sudo apt-get update
    #echo "<--- Updating package index $(date +'%Y%m%dT%H%M%S')"
    #echo "<--- Adding '$1' PPA $(date +'%Y%m%dT%H%M%S')"

    # DEB Install GCC packages
    echo "---> Installing GCC-5 packages $(date +'%Y%m%dT%H%M%S')"
    GCC_PKGS="cpp gcc g++ cmake lcov gcc-multilib"
    apt install -y ${GCC_PKGS}

    # DEB Install VPP packages to shorten build times
    echo "---> Installing VPP DEB_DEPENDS packages $(date +'%Y%m%dT%H%M%S')"
    VPP_PKGS="curl build-essential autoconf automake bison libssl-dev ccache \
      debhelper dkms git libtool libganglia1-dev libapr1-dev dh-systemd \
      libconfuse-dev git-review exuberant-ctags cscope indent pkg-config emacs"
    apt install -y ${VPP_PKGS}

    # DEB Install CSIT packages
    CSIT_PKGS="libxml2 libxml2-dev libxslt-dev zlib1g-dev bc unzip"
    apt install -y ${CSIT_PKGS}

    # DEB Install latest kernel and uio
    echo "---> Installing kernel image and header packages $(date +'%Y%m%dT%H%M%S')"
    DEB_PKGS="linux-image-extra-virtual linux-headers-virtual linux-headers-`uname -r`"
    apt install -y ${DEB_PKGS}

    # DEB Install deb_dpdk packages to shorten build times
    ###REMOVED sphinx-rtd-theme
    echo "---> Installing deb_dpdk packages $(date +'%Y%m%dT%H%M%S')"
    DEB_DPDK_PKGS="google-mock lsb-release dpkg-dev debian-xcontrol devscripts \
      pristine-tar dh-python python-sphinx libpcap0.8-dev libstdc++5 \
      python-scapy inkscape libxen-dev libxenstore3.0 python-sphinx-rtd-theme"
    apt install -y ${DEB_DPDK_PKGS}

    sudo apt install -y libcap-dev libpcap-dev

    TEXLIVE_PKGS="texlive-fonts-recommended tex-common texlive-base \
      texlive-binaries texlive-pictures texlive-latex-recommended \
      preview-latex-style texlive-latex-extra"
    apt install -y ${TEXLIVE_PKGS}
    echo "<--- Installing deb_dpdk packages $(date +'%Y%m%dT%H%M%S')"

    # DEB Manipulation tools, edits debugger, and LSB
    echo "---> Installing tools packages $(date +'%Y%m%dT%H%M%S')"
    TOOL_PKGS="iproute2 ethtool vlan bridge-utils vim gdb lsb-release gdbserver"
    apt install -y ${TOOL_PKGS}

    # DEB Updating CA certificates
    echo "---> Forcing CA certificate update $(date +'%Y%m%dT%H%M%S')"
      sudo update-ca-certificates -f > /dev/null 2>&1
    echo "<--- Forcing CA certificate update $(date +'%Y%m%dT%H%M%S')"
}

opensuse_systems() {

    function install_pkgs ()
    {
        for pkgs in $@; do
            zypper -n install "$pkgs"
        done
    }

     # Update to latest available packages and security bug-fixes
     zypper update -y

    cp /etc/cloud/cloud.cfg.orig /etc/cloud/cloud.cfg

    # Install openSuSE Development tool packages
    echo "--->Installing Development tool packages $(date +'%Y%m%dT%H%M%S')"
    ODTL="java-1_8_0-openjdk-devel indent pkg-config lcov cscope libtool ctags \
        bison libxml2-tools libxslt-devel python-virtualenv libopenssl-devel \
        libclang llvm-clang"
    install_pkgs "$ODTL"

    # Install openSuSE Development resources and libraries
    echo "--->Installing DEV resources & libraries $(date +'%Y%m%dT%H%M%S')"
    ODRL="kernel-devel libffi-devel libconfuse-devel libapr1 libapr1-devel \
        libexpat-devel pcre-devel libxml2-devel ruby-devel zlib-devel \
        glibc-devel-static libstdc++6 libclang llvm-clang check-devel"
    install_pkgs "$ODRL"

    # Install openSuSE Packaging utilities and resources
    echo "--->Installing PKG utilities & resources $(date +'%Y%m%dT%H%M%S')"
    OPP="yum-utils"
    install_pkgs "$OPP"

    # Install openSuSE Python resources and libraries
    echo "--->Installing Python resources & libraries $(date +'%Y%m%dT%H%M%S')"
    OPRL="python-devel python-setuptools python-pip python-wheel python-mock \
        python3-devel python3-pip python-rpm-macros shadow libnuma-devel \
        python3"
    install_pkgs "$OPRL"

    # Install openSuSE Documentation packages
    echo "---> Installing Documentation packages $(date +'%Y%m%dT%H%M%S')"
    ODP="doxygen graphviz asciidoc dblatex source-highlight python-sphinx \
        libxml2 python-jinja2 python-cffi python-pyparsing \
        python-sphinx_rtd_theme"
    install_pkgs "$ODP"

    # Install openSuSE Compliation packages
    echo "--->Installing Compliation packages $(date +'%Y%m%dT%H%M%S')"
    OCP="cpp gcc gcc-c++ cmake make gcc6 libstdc++-devel ruby-devel"
    install_pkgs "$OCP"

    # Install openSuSE Debugging tool packages
    echo "--->Installing Debugging tool packages $(date +'%Y%m%dT%H%M%S')"
    ODTP="valgrind rrdtool rrdtool-devel autoconf automake ccache chrpath"
    install_pkgs "$ODTP"

    # Install openSuSE Misc tool packages
    echo "--->Installing Misc tool packages $(date +'%Y%m%dT%H%M%S')"
    OMTP="openssl emacs curl git git-review unzip devscripts \
        iproute2 ethtool vlan bridge-utils vim gdb gdbserver \
        lsb-release distribution-release"
    install_pkgs "$OMTP"

    # Install openSuSE TLDK dependencies
    OTD="libpcap-devel libcap-devel"
    install_pkgs "${OTD}"
    zypper -n install -t pattern devel_basis

    # Leap 42.3 does not have a recent NASM version and VPP requires NASM 2.12 minimum so installing from TW repo
    zypper install -y \
        https://download.opensuse.org/tumbleweed/repo/oss/suse/x86_64/nasm-2.13.01-2.2.x86_64.rpm
}

all_systems() {

    echo 'Configure keep alive to prevent timeout during testing'
    local SSH_CFG=/etc/ssh/ssh_config
    echo "TCPKeepAlive        true" | sudo tee -a ${SSH_CFG} >/dev/null 2>&1
    echo "ServerAliveCountMax 30"   | sudo tee -a ${SSH_CFG} >/dev/null 2>&1
    echo "ServerAliveInterval 10"   | sudo tee -a ${SSH_CFG} >/dev/null 2>&1

    # Following installs hashicorp's packer binary which is required  for
    # ci-management-{verify,merge}-packer jobs
    mkdir /tmp/packer.io
    cd /tmp/packer.io
    wget https://releases.hashicorp.com/packer/0.12.2/packer_0.12.2_linux_amd64.zip
    unzip packer_0.12.2_linux_amd64.zip -d /usr/local/bin/
    # note: rename to packer.io to avoid conflict with cracklib packer
    mv /usr/local/bin/packer /usr/local/bin/packer.io

    # Install packagecloud.io
    gem install package_cloud
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
    opensuse)
        echo "---> openSuSE system detected"
        opensuse_systems
    ;;
    *)
        echo "---> Unknown operating system"
    ;;
esac

# execute steps for all systems
all_systems
