FROM centos:8
MAINTAINER Ed Kern <ejk@cisco.com>
LABEL Description="VPP centos8 OS build image" 
LABEL Vendor="cisco.com" 
LABEL Version="0.02"

# Setup the environment

RUN mkdir /workspace && mkdir -p /etc/ssh && mkdir -p /var/ccache

ENV CCACHE_DIR=/var/ccache
ENV MAKE_PARALLEL_FLAGS -j 4
ENV VPP_ZOMBIE_NOCHECK=1
ENV DPDK_DOWNLOAD_DIR=/w/Downloads
ENV VPP_PYTHON_PREFIX=/var/cache/vpp/python
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'
ENV NOTVISIBLE "in users profile"

#SSH timeout
#RUN touch /etc/ssh/ssh_config
RUN echo "TCPKeepAlive        true" | tee -a /etc/ssh/ssh_config #>/dev/null 2>&1
RUN echo "ServerAliveCountMax 30"   | tee -a /etc/ssh/ssh_config #>/dev/null 2>&1
RUN echo "ServerAliveInterval 10"   | tee -a /etc/ssh/ssh_config #>/dev/null 2>&1

# Configure locales
#RUN localectl set-locale "en_US.UTF-8" \
# && localectl status

#module
RUN echo uio_pci_generic >> /etc/modules

ADD files/CentOS-AppStream.repo /etc/yum.repos.d/CentOS-AppStream.repo
ADD files/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo

#RUN yum update -y && yum install -y deltarpm && yum clean all
#RUN yum update -y && yum install -y @base https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && yum clean all
RUN yum update -y && yum install -y epel-release && yum clean all
ADD files/epel.repo /etc/yum.repos.d/epel.repo

RUN yum update -y && yum install -y --enablerepo=epel \
	chrpath \
	git \
#	git-review \
	java-*-openjdk-devel \
	jq \
#	lcov \
	make \
#	nasm \
	sudo \
	unzip \
	xz \
	wget \
	nano \
	&& yum clean all

#packer install
#RUN wget https://releases.hashicorp.com/packer/1.1.3/packer_1.1.3_linux_amd64.zip && unzip packer_1.1.3_linux_amd64.zip -d /usr/local/bin/ && mv /usr/local/bin/packer /usr/local/bin/packer.io


RUN yum update -y && yum install -y --enablerepo=epel \
	asciidoc \
	apr-devel \
	cpp \
#       c++ \
	cmake \
#       dblatex  \
#       doxygen \
	epel-rpm-macros \
	gcc \
	graphviz \
	indent \
	kernel-devel \
	libxml2 \
	libffi-devel \
	make \
	openssl-devel \
	python2-devel \
	python2-virtualenv \
	python2-setuptools \
#       python2-cffi \
        python2-pip \
  	python2-jinja2 \
#       python2-sphinx \
        source-highlight \
        rpm \
	valgrind \
	yum-utils \
	&& yum clean all

RUN yum update -y && yum install -y \
#       ganglia-devel \
	libconfuse-devel \
	mock \
	&& yum clean all

#RUN alternatives --set java /usr/lib/jvm/jre-1.7.0-openjdk.x86_64/bin/java
#RUN alternatives --set java_sdk_openjdk /usr/lib/jvm/java-1.7.0-openjdk.x86_64

RUN pip2 install --upgrade pip
RUN pip2 install pycap scapy

RUN yum update -y && yum install -y --enablerepo=epel \
	autoconf \
	automake \
	bison \
	ccache \
	cscope \
	curl \
	dkms \
	git \
#	git-review \
	libtool \
#    libconfuse-dev \
#    libpcap-devel \
    libcap-devel \
    scapy \
    && yum clean all

#puppet
RUN yum update -y && yum install -y --enablerepo=epel \
	libxml2-devel \
	libxslt-devel \
	ruby-devel \
	zlib-devel \
	gcc-c++ \
	&& yum clean all

#outdated ruby pos
RUN yum update -y && yum install -y --enablerepo=epel \
	git-core \
	zlib \
	zlib-devel \
	gcc-c++ \
	patch \
	readline \
	readline-devel \
#	libyaml-devel \
	libffi-devel \
	openssl-devel \
	make \
	bzip2 \
	autoconf \
	automake \
	libtool \
	bison \
	curl \
	sqlite-devel \
	&& yum clean all

ENV PATH="/root/.rbenv/bin:${PATH}"
ENV PATH="/root/.rbenv/shims:${PATH}"

RUN curl -sL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-installer | bash - 
RUN rbenv init -
RUN rbenv install 2.5.1 && rbenv global 2.5.1
#&& echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc && echo 'eval "$(rbenv init -)"' >> ~/.bashrc &&


RUN gem install rake
RUN gem install package_cloud

RUN yum update -y && yum install -y --enablerepo=epel \
	apr-util \
	byacc \
	diffstat \
	dwz \
	flex \
	gcc-gfortran \
	gettext-devel \
	glibc \
	glibc-langpack-en \
	intltool \
#	nasm \
	patchutils \
#	rcs \
	redhat-lsb \
	redhat-rpm-config \
	rpm-build \
	rpm-sign \
	subversion \
	swig \
	systemtap \
	&& yum clean all

#RUN yum update -y && yum install -y --enablerepo=epel-debuginfo --enablerepo=base-debuginfo \
# RUN yum update -y && yum install -y --enablerepo=epel-debuginfo \
# 	e2fsprogs-debuginfo \
# 	glibc-debuginfo \
# 	krb5-debuginfo \
# 	nss-softokn-debuginfo \
# 	openssl-debuginfo \
# 	yum-plugin-auto-update-debug-info \
# 	zlib-debuginfo \
# 	glibc-debuginfo-common \
# 	&& yum clean all

RUN yum update -y && yum groupinstall -y "development tools" \
	&& yum clean all
# Libraries needed during compilation to enable all features of Python:
RUN yum update -y \
	&& yum install -y --enablerepo=epel \
	zlib-devel \
	bzip2-devel \
	openssl-devel \
	ncurses-devel \
	sqlite-devel \
	readline-devel \
	tk-devel \
	gdbm-devel \
#       db4-devel \
#       libpcap-devel \
	xz-devel \
	expat-devel \
	wget \
    clang \
    llvm \
    numactl-devel \
    check-devel \
    check \
    boost \
    boost-devel \
    mbedtls-devel \
    xmlstarlet \
#   centos-release-scl \
    yamllint \
	&& yum clean all

#centos8 
RUN dnf config-manager --set-enabled PowerTools \
	&& yum install -y --enablerepo=epel \
	compat-openssl10 \
	python3-jsonschema \
	selinux-policy \
	selinux-policy-devel \
	glibc-static \
	ninja-build \
	&& yum clean all

# Python 2.7.13:
# RUN wget http://python.org/ftp/python/2.7.13/Python-2.7.13.tar.xz \
#     && tar xf Python-2.7.13.tar.xz \
#     && cd Python-2.7.13 \
#     && ./configure --prefix=/usr/local --enable-unicode=ucs4 --enable-shared LDFLAGS="-Wl,-rpath /usr/local/lib" \
#     && make \
#     && make install \
#     && strip /usr/local/lib/libpython2.7.so.1.0 \
#     && cd .. \
#     && rm -rf Python* \
#     && wget https://bootstrap.pypa.io/get-pip.py \
#     && /usr/local/bin/python get-pip.py

RUN pip2 install six scapy==2.3.3 pyexpect subprocess32 cffi git+https://github.com/klement/py-lispnetworking@setup ply
RUN mkdir -p /w/workspace && mkdir -p /var/ccache && ln -s /var/ccache /tmp/ccache
ENV CCACHE_DIR=/var/ccache
ENV CCACHE_READONLY=true
RUN mkdir -p /var/cache/vpp/python
RUN mkdir -p /w/Downloads
# RUN wget -O /w/Downloads/dpdk-18.02.1.tar.xz http://dpdk.org/browse/dpdk-stable/snapshot/dpdk-stable-18.02.1.tar.xz
# RUN wget -O /w/Downloads/dpdk-18.05.tar.xz http://dpdk.org/browse/dpdk/snapshot/dpdk-18.05.tar.xz
# RUN wget -O /w/Downloads/v0.47.tar.gz http://github.com/01org/intel-ipsec-mb/archive/v0.47.tar.gz
# RUN wget -O /w/Downloads/v0.48.tar.gz http://github.com/01org/intel-ipsec-mb/archive/v0.48.tar.gz
# RUN wget -O /w/Downloads/v0.49.tar.gz http://github.com/01org/intel-ipsec-mb/archive/v0.49.tar.gz

ADD files/lf-update-java-alternatives /usr/local/bin/lf-update-java-alternatives
RUN chmod 755 /usr/local/bin/lf-update-java-alternatives
#RUN curl -s https://packagecloud.io/install/repositories/fdio/master/script.rpm.sh | sudo bash

# CSIT requirements
RUN dnf config-manager --set-enabled PowerTools \
    && yum install -y --enablerepo=epel \
	curl \
        git \
        libpcap-devel \
        openssh-clients \
        openssh-server \
        net-tools \
        pciutils \
        python3-cffi \
        python3-pip \
        python3-setuptools \
        socat \
        sshpass \
        strongswan \
        sudo \
        supervisor \
        tar \
        tcpdump \
        unzip \
        vim \
	virtualenv \
        wget \
        zlib-devel \
      	&& yum clean all

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
		ply==3.11 \
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

# CSIT ARM workaround
RUN pip3 install scipy==1.1.0

# Configure locales
#RUN localectl set-locale "en_US.UTF-8" \
# && localectl status

# Fix permissions
# RUN chown root:syslog /var/log \
# && chmod 755 /etc/default

# Create directory structure
RUN mkdir -p /tmp/dumps \
 && mkdir -p /var/cache/vpp/python \
 && mkdir -p /var/run/sshd

# SSH settings
RUN echo 'root:Csit1234' | chpasswd \
 && sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config \
 && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
 && echo "export VISIBLE=now" >> /etc/profile

ADD files/sshconfig /root/.ssh/config
ADD files/badkey /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa
#RUN mv /usr/bin/sar /usr/bin/sar.old && ln -s /bin/true /usr/bin/sar
RUN ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N '' && ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' && ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''

#include bits from registry image
RUN rm -rf /home/jenkins && useradd -ms /bin/bash jenkins && chown -R jenkins /w && chown -R jenkins /var/ccache && chown -R jenkins /var/cache/vpp #&& mv /usr/bin/sar /usr/bin/sar.old && ln -s /bin/true /usr/bin/sar
ADD files/jenkins /etc/sudoers.d/jenkins
ADD files/supervisord.conf /etc/supervisord/supervisord.conf
ENV PATH=/root/.local/bin:/home/jenkins/.local/bin:${PATH}

#csit-sut ssh bits for the end
EXPOSE 22

CMD ["sh", "-c", "rm -f /dev/shm/db /dev/shm/global_vm /dev/shm/vpe-api; /usr/bin/supervisord -c /etc/supervisord/supervisord.conf; /usr/sbin/sshd -D"]
