FROM ubuntu:16.04
MAINTAINER Ed Kern <ejk@cisco.com>
LABEL Description="VPP ubuntu 16 baseline" 
LABEL Vendor="cisco.com" 
LABEL Version="3.1"


# Setup the environment
ENV DEBIAN_FRONTEND=noninteractive
ENV MAKE_PARALLEL_FLAGS -j 4
ENV DOCKER_TEST=True
ENV VPP_ZOMBIE_NOCHECK=1
ENV DPDK_DOWNLOAD_DIR=/w/Downloads
ENV VPP_PYTHON_PREFIX=/var/cache/vpp/python

RUN apt-get -q update && \
    apt-get install -y -qq \
        bash \
        bash-completion \
        bc \
        biosdevname \
        ca-certificates \
        cloud-init \
        cron \
        curl \
	    libcurl3-gnutls \
        dbus \
        dstat \
        ethstatus \
        file \
        fio \
        htop \
        ifenslave \
        ioping \
        iotop \
        iperf \
        iptables \
        iputils-ping \
        less \
        locate \
        lsb-release \
        lsof \
        make \
        man-db \
        mdadm \
        mg \
        mosh \
        mtr \
        multipath-tools \
        nano \
        net-tools \
        netcat \
        nmap \
        ntp \
        ntpdate \
        open-iscsi \
        python-apt \
        python-pip \
        python-yaml \
        rsync \
        rsyslog \
        screen \
        shunit2 \
        socat \
        software-properties-common \
        ssh \
        sudo \
        sysstat \
        tar \
        tcpdump \
        tmux \
        traceroute \
        unattended-upgrades \
        uuid-runtime \
        vim \
        wget \
        apt-transport-https \
        default-jre-headless \
        chrpath \
        nasm \
        && rm -rf /var/lib/apt/lists/*

RUN add-apt-repository -y ppa:openjdk-r/ppa

RUN apt-get -q update && \
    apt-get install -y -qq \
        unzip \
        xz-utils \
        puppet \
        git \
        git-review \
        libxml-xpath-perl \
        make \
        wget \
        openjdk-8-jdk \
        openjdk-11-jdk \
        jq \
        libffi-dev \
	    python-all \
        && rm -rf /var/lib/apt/lists/*

RUN apt-get -q update && \
    apt-get install -y -qq \
        autoconf \
        automake \
        autotools-dev \
        bison \
        ccache \
        cscope \
        debhelper \
        dh-apparmor \
        dh-systemd \
        dkms \
        ed \
        exuberant-ctags \
        gettext \
        gettext-base \
        intltool-debian \
        indent \
        lcov \
        libapr1 \
        libapr1-dev \
        libasprintf-dev \
        libbison-dev \
        libconfuse-common \
        libconfuse-dev \
        libconfuse0 \
        libcroco3 \
        libexpat1-dev \
        libganglia1 \
        libganglia1-dev \
        libgd-gd2-perl \
        libgettextpo-dev \
        libgettextpo0 \
        libltdl-dev \
        libmail-sendmail-perl \
        libmbedtls-dev \
        libpython-dev \
        libpython2.7-dev \
        libsctp-dev \
        libsigsegv2 \
        libssl-dev \
        libssl-doc \
        libsys-hostname-long-perl \
        libtool \
        libunistring0 \
        m4 \
        pkg-config \
        po-debconf \
        python-dev \
        python-virtualenv \
        python2.7-dev \
        uuid-dev \
        zlib1g-dev \
        locales \
        llvm \
        clang \
        clang-format \
        clang-5.0 \
        libboost-all-dev \
        ruby-dev \
        zile \
        default-jdk-headless \
        check \
        libsubunit-dev \
        libsubunit0 \
        emacs \
        gdb \
        libpcap-dev \
        python-ply \
        iperf3 \
        libibverbs-dev \
        dtach \
        cmake \
        cmake-data \
        libarchive13 \
        libcurl3 \
        liblzo2-2 \
        ninja-build \
        && rm -rf /var/lib/apt/lists/*

#Repoint clang
RUN update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-5.0 1000 && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-5.0 1000

# For the docs
RUN apt-get -q update && \
    apt-get install -y -qq \
        python-markupsafe \
        python-jinja2 \
        python-pyparsing \
        doxygen \
        graphviz \
        xmlstarlet \
        && rm -rf /var/lib/apt/lists/*

# Configure locales
RUN locale-gen en_US.UTF-8 && \
    dpkg-reconfigure locales

# Fix permissions
RUN chown root:syslog /var/log \
    && chmod 755 /etc/default

RUN mkdir /tmp/dumps
RUN mkdir /workspace && mkdir -p /var/ccache && ln -s /var/ccache /tmp/ccache
ENV CCACHE_DIR=/var/ccache
ENV CCACHE_READONLY=true

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN gem install rake
RUN gem install package_cloud
RUN pip install six scapy==2.3.3 pyexpect subprocess32 cffi git+https://github.com/klement/py-lispnetworking@setup pycodestyle
#Below are requirements for csit
RUN pip install robotframework==2.9.2 paramiko==1.16.0 scp==0.10.2 ipaddress==1.0.16 interruptingcow==0.6 PyYAML==3.12 pykwalify==1.5.0 \
        enum34==1.1.2 requests==2.9.1 ecdsa==0.13 pycrypto==2.6.1 pypcap==1.1.5 psutil

RUN mkdir -p /var/cache/vpp/python
RUN mkdir -p /w/Downloads
RUN wget -O /w/Downloads/nasm-2.13.01.tar.xz http://www.nasm.us/pub/nasm/releasebuilds/2.13.01/nasm-2.13.01.tar.xz
RUN wget -O /w/Downloads/dpdk-18.02.1.tar.xz http://fast.dpdk.org/rel/dpdk-18.02.1.tar.xz
#RUN wget -O /w/Downloads/dpdk-18.02.1.tar.xz http://dpdk.org/browse/dpdk-stable/snapshot/dpdk-stable-18.02.1.tar.xz
RUN wget -O /w/Downloads/dpdk-18.05.tar.xz http://fast.dpdk.org/rel/dpdk-18.05.tar.xz
#RUN wget -O /w/Downloads/dpdk-18.05.tar.xz http://dpdk.org/browse/dpdk/snapshot/dpdk-18.05.tar.xz
RUN wget -O /w/Downloads/dpdk-17.11.tar.xz http://fast.dpdk.org/rel/dpdk-17.11.tar.xz
RUN wget -O /w/Downloads/v0.47.tar.gz http://github.com/01org/intel-ipsec-mb/archive/v0.47.tar.gz
RUN wget -O /w/Downloads/v0.48.tar.gz http://github.com/01org/intel-ipsec-mb/archive/v0.48.tar.gz
RUN wget -O /w/Downloads/v0.49.tar.gz http://github.com/01org/intel-ipsec-mb/archive/v0.49.tar.gz

#RUN git clone https://gerrit.fd.io/r/vpp /workspace/ubuntu16 && cd /workspace/ubuntu16; make UNATTENDED=yes install-dep && rm -rf /workspace/ubuntu16 && rm -rf /var/lib/apt/lists/*
#ADD files/99fd.io.list /etc/apt/sources.list.d/99fd.io.list
#ADD files/fdio_master.list /etc/apt/sources.list.d/fdio_master.list

ADD files/sshconfig /root/.ssh/config
ADD files/badkey /root/.ssh/id_rsa
ADD files/lf-update-java-alternatives /usr/local/bin/lf-update-java-alternatives
RUN chmod 755 /usr/local/bin/lf-update-java-alternatives
RUN chmod 600 /root/.ssh/id_rsa
RUN curl -L https://packagecloud.io/fdio/master/gpgkey |sudo apt-key add -

RUN curl -s https://packagecloud.io/install/repositories/fdio/master/script.deb.sh | sudo bash

#RUN apt update && apt install -y vpp-dpdk-dev vpp-dpdk-dkms 
RUN mkdir -p /w/workspace && mkdir -p /home/jenkins && mkdir -p /run/shm




