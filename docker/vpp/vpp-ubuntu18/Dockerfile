FROM ubuntu:18.04
MAINTAINER Ed Kern <ejk@cisco.com>
LABEL Description="VPP ubuntu 18 baseline" 
LABEL Vendor="cisco.com" 
LABEL Version="1.1"


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
        rsync \
        rsyslog \
        screen \
        shunit2 \
        socat \
        software-properties-common \
        ssh \
        sshpass \
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
        chrpath \
        nasm \
        dtach \
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
        libconfuse-doc \
        libconfuse-dev \
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
        m4 \
        pkg-config \
        po-debconf \
        uuid-dev \
        zlib1g-dev \
        locales \
        llvm \
        clang \
        clang-format \
        libboost-all-dev \
        ruby-dev \
        zile \
        check \
        libsubunit-dev \
        libsubunit0 \
        emacs \
        gdb \
        libpcap-dev \
        iperf3 \
        libibverbs-dev \
        apt-utils \
        python-all \
        python-apt \
        python-cffi \
        python-cffi-backend \
        python-dev \
        python-enum34 \
        python-pip \
        python-ply \
        python-setuptools \
        python-virtualenv \
        python-yaml \
        python3-all \
        python3-apt \
        python3-cffi \
        python3-cffi-backend \
        python3-dev \
        python3-pip \
        python3-ply \
        python3-setuptools \
        python3-virtualenv \
        python3-venv \
        && rm -rf /var/lib/apt/lists/*

# For the docs
RUN apt-get -q update && \
    apt-get install -y -qq \
        python-markupsafe \
        python-jinja2 \
        python-pyparsing \
        doxygen \
        graphviz \
        && rm -rf /var/lib/apt/lists/*

RUN apt-get -q update && \
    apt-get install -y -qq \
        cmake \
        cmake-data \
        libarchive13 \
        liblzo2-2 \
        librhash0 \
        libuv1 \
        ninja-build \
        cmake-doc \
        lrzip \
        xmlstarlet \
        g++-8 \
        gcc-8 \
        yamllint \
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
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 700 --slave /usr/bin/g++ g++ /usr/bin/g++-7 && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 800 --slave /usr/bin/g++ g++ /usr/bin/g++-8

RUN curl -L https://packagecloud.io/fdio/master/gpgkey |sudo apt-key add -
#ADD files/99fd.io.list /etc/apt/sources.list.d/99fd.io.list
#ADD files/fdio_master.list /etc/apt/sources.list.d/fdio_master.list

#RUN apt update && apt install -y vpp-dpdk-dev vpp-dpdk-dkms || true
#RUN mkdir -p /w/dpdk && cd /w/dpdk; apt-get download vpp-dpdk-dkms || true

#RUN mkdir -p /w/workspace/vpp-verify-master-ubuntu1804 && mkdir -p /home/jenkins
RUN mkdir -p /w/workspace && mkdir -p /home/jenkins
RUN apt-get purge -y default-jre-headless openjdk-9-jdk-headless openjdk-9-jre-headless || true

ADD files/default-jdk-headless_1.8-59ubuntu2_amd64.deb /tmp/default-jdk-headless_1.8-59ubuntu2_amd64.deb
ADD files/default-jre-headless_1.8-59ubuntu2_amd64.deb /tmp/default-jre-headless_1.8-59ubuntu2_amd64.deb

RUN apt-get install -y /tmp/default-jre-headless_1.8-59ubuntu2_amd64.deb /tmp/default-jdk-headless_1.8-59ubuntu2_amd64.deb
ADD files/jre /etc/apt/preferences.d/jre
ADD files/pc_push /usr/local/bin/pc_push
ADD files/packagecloud /root/.packagecloud
ADD files/packagecloud_api /root/packagecloud_api
ADD files/lf-update-java-alternatives /usr/local/bin/lf-update-java-alternatives
RUN chmod 755 /usr/local/bin/lf-update-java-alternatives
RUN gem install rake
RUN gem install package_cloud

# VPP PIP pre-cahce
RUN pip install \
        six \
	scapy==2.3.3 \
	pyexpect \
	subprocess32 \
	cffi \
	git+https://github.com/klement/py-lispnetworking@setup \
	pycodestyle

# CSIT PIP pre-cache
RUN pip3 install \
        ecdsa==0.13.3 \
        paramiko==2.6.0 \
        pycrypto==2.6.1 \
        pypcap==1.2.3 \
        PyYAML==5.1.1 \
        requests==2.22.0 \
        robotframework==3.1.2 \
        scapy==2.4.3 \
        scp==0.13.2 \
        ansible==2.7.8 \
        dill==0.2.8.2 \
        numpy==1.17.3 \
        hdrhistogram==0.6.1 \
        pandas==0.25.3 \
        plotly==4.1.1 \
        PTable==0.9.2 \
        Sphinx==2.2.1 \
        sphinx-rtd-theme==0.4.0 \
        sphinxcontrib-programoutput==0.15 \
        sphinxcontrib-robotdoc==0.11.0 \
        alabaster==0.7.12 \
        Babel==2.7.0 \
        bcrypt==3.1.7 \
        certifi==2019.9.11 \
        cffi==1.13.2 \
        chardet==3.0.4 \
        cryptography==2.8 \
        docutils==0.15.2 \
        future==0.18.2 \
        idna==2.8 \
        imagesize==1.1.0 \
        Jinja2==2.10.3 \
        MarkupSafe==1.1.1 \
        packaging==19.2 \
        pbr==5.4.3 \
	ply==3.11 \
        pycparser==2.19 \
        Pygments==2.4.2 \
        PyNaCl==1.3.0 \
        pyparsing==2.4.4 \
        python-dateutil==2.8.1 \
        pytz==2019.3 \
        retrying==1.3.3 \
        six==1.13.0 \
        snowballstemmer==2.0.0 \
        sphinxcontrib-applehelp==1.0.1 \
        sphinxcontrib-devhelp==1.0.1 \
        sphinxcontrib-htmlhelp==1.0.2 \
        sphinxcontrib-jsmath==1.0.1 \
        sphinxcontrib-qthelp==1.0.2 \
        sphinxcontrib-serializinghtml==1.1.3 \
        urllib3==1.25.6

# CSIT PIP pre-cache - ARM workaround
RUN pip3 install scipy==1.1.0

RUN mkdir -p /var/cache/vpp/python
RUN mkdir -p /w/Downloads
#RUN wget -O /w/Downloads/nasm-2.13.01.tar.xz http://www.nasm.us/pub/nasm/releasebuilds/2.13.01/nasm-2.13.01.tar.xz
#RUN wget -O /w/Downloads/dpdk-18.02.tar.xz http://fast.dpdk.org/rel/dpdk-18.02.tar.xz
#RUN wget -O /w/Downloads/dpdk-17.11.tar.xz http://fast.dpdk.org/rel/dpdk-17.11.tar.xz
RUN wget -O /w/Downloads/dpdk-18.02.1.tar.xz http://dpdk.org/browse/dpdk-stable/snapshot/dpdk-stable-18.02.1.tar.xz
RUN wget -O /w/Downloads/dpdk-18.05.tar.xz http://dpdk.org/browse/dpdk/snapshot/dpdk-18.05.tar.xz
RUN wget -O /w/Downloads/dpdk-18.08.tar.xz http://dpdk.org/browse/dpdk/snapshot/dpdk-18.08.tar.xz
RUN wget -O /w/Downloads/v0.47.tar.gz http://github.com/01org/intel-ipsec-mb/archive/v0.47.tar.gz
RUN wget -O /w/Downloads/v0.48.tar.gz http://github.com/01org/intel-ipsec-mb/archive/v0.48.tar.gz
RUN wget -O /w/Downloads/v0.49.tar.gz http://github.com/01org/intel-ipsec-mb/archive/v0.49.tar.gz
RUN curl -s https://packagecloud.io/install/repositories/fdio/master/script.deb.sh | sudo bash

#bad and open ssh keys for csit
ADD files/sshconfig /root/.ssh/config
ADD files/badkey /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa

# for lftools
RUN rm -rf /home/jenkins && useradd -ms /bin/bash jenkins && chown -R jenkins /w && chown -R jenkins /var/ccache && chown -R jenkins /var/cache/vpp && mv /usr/bin/sar /usr/bin/sar.old && ln -s /bin/true /usr/bin/sar
ENV PATH=/root/.local/bin:/home/jenkins/.local/bin:${PATH}

