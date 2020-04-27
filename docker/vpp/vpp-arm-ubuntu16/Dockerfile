FROM arm64v8/ubuntu:16.04
MAINTAINER Ed Kern <ejk@cisco.com>
LABEL Description="arm VPP ubuntu 16 baseline" 
LABEL Vendor="cisco.com" 
LABEL Version="3.0"


# Setup the environment
ENV DEBIAN_FRONTEND=noninteractive
CMD []
RUN echo 'foo' || true
RUN apt-get update || true
RUN echo 'bar'
RUN apt-get install -y -qq \
        bash \
        bash-completion \
        bc \
        biosdevname \
        ca-certificates \
        cloud-init \
        cron \
        curl \
        dbus \
        dstat \
        ethstatus \
        file \
        fio \
        htop 
        #\
        # ifenslave \
        # ioping \
        # iotop \
        # iperf \
        # iptables \
        # iputils-ping \
        # less \
        # locate \
        # lsb-release \
        # lsof \
        # make \
        # man-db \
        # mdadm \
        # mg \
        # mosh \
        # mtr \
        # multipath-tools \
        # nano \
        # net-tools \
        # netcat \
        # nmap \
        # ntp \
        # ntpdate \
        # open-iscsi \
        # python-apt \
        # python-pip \
        # python-yaml \
        # rsync \
        # rsyslog \
        # screen \
        # shunit2 \
        # socat \
        # software-properties-common \
        # ssh \
        # sudo \
        # sysstat \
        # tar \
        # tcpdump \
        # tmux \
        # traceroute \
        # unattended-upgrades \
        # uuid-runtime \
        # vim \
        # wget \
        # apt-transport-https \
        # default-jre-headless \
        # chrpath \
        # nasm \
        # && rm -rf /var/lib/apt/lists/*

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
        libboost-all-dev \
        ruby-dev \
        xmlstarlet \
        && rm -rf /var/lib/apt/lists/*


# Configure locales
RUN locale-gen en_US.UTF-8 && \
    dpkg-reconfigure locales

# Fix permissions
RUN chown root:syslog /var/log \
    && chmod 755 /etc/default

RUN mkdir /workspace && mkdir -p /var/ccache && ln -s /var/ccache /tmp/ccache
ENV CCACHE_DIR=/var/ccache
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN gem install rake
RUN gem install package_cloud
RUN pip install scapy
RUN git clone https://gerrit.fd.io/r/vpp /workspace/ubuntu16 && cd /workspace/ubuntu16; make UNATTENDED=yes install-dep && rm -rf /workspace/ubuntu16 && rm -rf /var/lib/apt/lists/*




