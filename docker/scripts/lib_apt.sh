# lib_apt.sh - Docker build script apt library.
#              For import only.

# Copyright (c) 2021 Cisco and/or its affiliates.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Don't import more than once.
if [ -n "$(alias lib_apt_imported 2> /dev/null)" ] ; then
    return 0
fi
alias lib_apt_imported=true

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. $CIMAN_DOCKER_SCRIPTS/lib_common.sh
. $CIMAN_DOCKER_SCRIPTS/lib_csit.sh

dump_apt_package_list() {
    branchname="$(echo $branch | sed -e 's,/,_,')"
    dpkg -l > \
         "$DOCKER_BUILD_LOG_DIR/$FDIOTOOLS_IMAGENAME-$branchname-apt-packages.log"
}

apt_install_packages() {
    apt-get install -y --allow-downgrades --allow-remove-essential \
            --allow-change-held-packages $@
}

# Used for older OS distro's which are incompatible
# with modern distro cmake vesrion
apt_override_cmake_install_with_pip3_version() {
    local os_cmake="/usr/bin/cmake"
    local os_cmake_ver="$($os_cmake --version | head -1)"
    local pip3_cmake="/usr/local/bin/cmake"

    python3 -m pip install --disable-pip-version-check cmake || true
    local pip3_cmake_ver="$($pip3_cmake --version | head -1)"
    echo_log "Overriding $OS_NAME '$os_cmake_ver' with '$pip3_cmake_ver'!"
    sudo apt-get remove -y cmake --autoremove || true
    update-alternatives --quiet --remove-all cmake || true
    update-alternatives --quiet --install $os_cmake cmake $pip3_cmake 100
    echo_log "Default cmake ($(which cmake)) version: '$(cmake --version | head -1)'!"
}

generate_apt_dockerfile_common() {
    local executor_class=$1
    local executor_image=$2

    cat <<EOF >>$DOCKERFILE

# Create download dir to cache external tarballs
WORKDIR $DOCKER_DOWNLOADS_DIR

# Copy-in temporary build tree containing
# ci-management, vpp, & csit git repos
WORKDIR $DOCKER_BUILD_DIR
COPY . .

# Build Environment Variables
ENV DEBIAN_FRONTEND=noninteractive
ENV FDIOTOOLS_IMAGE=$executor_image
ENV FDIOTOOLS_EXECUTOR_CLASS=$executor_class
ENV CIMAN_ROOT="$DOCKER_CIMAN_ROOT"
ENV PATH=$PATH:$DOCKER_CIMAN_ROOT/docker/scripts

# Configure locales
RUN apt-get update -y -q \\
    && apt-get install -y locales \\
    && sed -i 's/# \(en_US\.UTF-8 .*\)/\1/' /etc/locale.gen \\
    && locale-gen en_US.UTF-8 \\
    && dpkg-reconfigure --frontend=noninteractive locales \\
    && update-locale LANG=en_US.UTF-8 \\
    && rm -r /var/lib/apt/lists/*
ENV LANG=en_US.UTF-8 LANGUAGE=en_US LC_ALL=en_US.UTF-8

# Install baseline packages (minimum build & utils).
#
# ci-management global-jjb requirements:
#       facter
#       python3-pip
#       python3-venv
#   for lftools:
#       xmlstarlet
#       libxml2-dev
#       libxslt-dev
#   from packer/provision/baseline.sh:
#       unzip
#       xz-utils
#       git
#       git-review
#       libxml2-dev
#       libxml-xpath-perl
#       libxslt-dev
#       make
#       wget
#       jq
#
# Python build from source requirements:
#       build-essential
#
# TODO: Fix broken project requirement install targets
#
#   graphviz         for 'make bootstrap-doxygen' (VPP)
#   doxygen          for 'make doxygen' (VPP)
#   enchant          for 'make docs' (VPP)
#   libffi-dev       for python cffi install (Ubuntu20.04/VPP/aarch64)
#   liblapack-dev    for python numpy/scipy (CSIT/aarch64)
#   libopenblas-dev  for python numpy/scipy (CSIT/aarch64)
#   libpcap-dev      for python pypcap install (CSIT)
#   sshpass          for CSIT jobs
#
RUN apt-get update -q \\
    && apt-get install -y -qq \\
        apt-transport-https \\
        apt-utils \\
        curl \\
        ca-certificates \\
        default-jdk \\
        default-jre \\
        doxygen \\
        enchant \\
        emacs \\
        facter \\
        gawk \\
        gdb \\
        gfortran \\
        git \\
        git-review \\
        gnupg-agent \\
        graphviz \\
        iproute2 \\
        iputils-clockdiff \\
        iputils-ping \\
        iputils-tracepath \\
        jq \\
        libffi-dev \\
        liblapack-dev \\
        libopenblas-dev \\
        libpcap-dev \\
        libxml2-dev \\
        libxml-xpath-perl \\
        libxslt-dev \\
        make \\
        python3-pip \\
        python3-venv \\
        rsync \\
        ruby-dev \\
        software-properties-common \\
        sshpass \\
        sudo \\
        traceroute \\
        tree \\
        vim \\
        wget \\
        xmlstarlet \\
        xz-utils \\
    && curl -L https://packagecloud.io/fdio/master/gpgkey | sudo apt-key add - \\
    && curl -s https://packagecloud.io/install/repositories/fdio/master/script.deb.sh | sudo bash \\
    && curl -fsSL https://get.docker.com | sh \\
    && rm -r /var/lib/apt/lists/*

# Install packages for all project branches
#
RUN apt-get update -q \\
    && dbld_vpp_install_packages.sh \\
    && dbld_csit_install_packages.sh \\
    && rm -r /var/lib/apt/lists/*
EOF
}

generate_apt_dockerfile_clean() {
    cat <<EOF >>$DOCKERFILE

# Clean up copy-in build tree
RUN dbld_dump_build_logs.sh \\
    && rm -rf /tmp/*
EOF
}

# Generate 'builder' class apt dockerfile
builder_generate_apt_dockerfile() {
    local executor_class=$1
    local executor_os_name=$2
    local executor_image=$3
    local vpp_install_skip_sysctl_envvar="";

    if grep -q debian-9  <<<$executor_os_name ; then
        # Workaround to VPP package installation failure on debian-9
        vpp_install_skip_sysctl_envvar="ENV VPP_INSTALL_SKIP_SYSCTL=1"
    fi
    generate_apt_dockerfile_common $executor_class $executor_image
    cat <<EOF >>$DOCKERFILE

# Install LF-IT requirements
RUN apt-get update -q \\
    && dbld_lfit_requirements.sh \\
    && rm -r /var/lib/apt/lists/*

# CI Runtime Environment
WORKDIR /
$vpp_install_skip_sysctl_envvar
ENV VPP_ZOMBIE_NOCHECK=1

# TODO: Mount ccache volume into docker container, then remove this.
ENV CCACHE_DISABLE=1

# DAW-FIXME: Verify that the builder images don't require gems (rake & package_cloud)
#RUN gem install rake package_cloud \\
#    && curl -s https://packagecloud.io/install/repositories/fdio/master/script.deb.sh | sudo bash
EOF
    generate_apt_dockerfile_clean
}

# Generate 'csit' class apt dockerfile
csit_generate_apt_dockerfile() {
    echo_log "ERROR: ${FUNCNAME[0]} TBD!"
    exit 1
}

# Generate 'csit_dut' class apt dockerfile
csit_dut_generate_apt_dockerfile() {
    local executor_class=$1
    local executor_os_name=$2
    local executor_image=$3

    csit_dut_generate_docker_build_files
    generate_apt_dockerfile_common $executor_class $executor_image
    cat <<EOF >>$DOCKERFILE

# Install csit_dut specific packages
RUN apt-get update -q \\
    && apt-get install -y -qq \\
        net-tools \\
        openssh-server \\
        pciutils \\
        rsyslog \\
        supervisor \\
    && rm -r /var/lib/apt/lists/*

# Fix permissions
RUN chown root:syslog /var/log \\
    && chmod 755 /etc/default

# Create directory structure
RUN mkdir -p /tmp/dumps \\
    && mkdir -p /var/run/sshd

# SSH settings
RUN echo 'root:Csit1234' | chpasswd \\
 && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \\
 && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \\
 && echo "export VISIBLE=now" >> /etc/profile

EXPOSE 2222

COPY files/supervisord.conf /etc/supervisor/supervisord.conf

CMD ["sh", "-c", "rm -f /dev/shm/db /dev/shm/global_vm /dev/shm/vpe-api; /usr/bin/supervisord -c /etc/supervisor/supervisord.conf; /usr/sbin/sshd -D -p 2222"]
EOF
    generate_apt_dockerfile_clean
}

# Generate 'csit_shim' class apt dockerfile
csit_shim_generate_apt_dockerfile() {
    local executor_class=$1
    local executor_os_name=$2
    local executor_image=$3

    csit_shim_generate_docker_build_files
    cat <<EOF >>$DOCKERFILE

# Copy-in temporary build tree containing
# ci-management, vpp, & csit git repos
WORKDIR $DOCKER_BUILD_DIR
COPY . .

# Setup the environment
ENV DEBIAN_FRONTEND=noninteractive
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

ADD files/wrapdocker /usr/local/bin/wrapdocker
RUN chmod +x /usr/local/bin/wrapdocker

# Install packages and Docker
RUN apt-get update -q \\
 && apt-get install -y  \\
        bash \\
        curl \\
        iproute2 \\
        locales \\
        ssh \\
        sudo \\
        tzdata \\
        uuid-runtime \\
 && curl -fsSL https://get.docker.com | sh \\
 && rm -rf /var/lib/apt/lists/*

# Configure locales
RUN locale-gen en_US

RUN mkdir /var/run/sshd
RUN echo 'root:Csit1234' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Need volume for sidecar docker launches
VOLUME /var/lib/docker

# SSH to listen on port 6022 in shim
RUN echo 'Port 6022' >>/etc/ssh/sshd_config
RUN echo 'Port 6023' >>/etc/ssh/sshd_config
ADD files/badkeypub /root/.ssh/authorized_keys
ADD files/sshconfig /root/.ssh/config

# Start sshd by default
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
EOF
}

generate_apt_dockerfile() {
    local executor_class=$1
    local executor_os_name=$2
    local from_image=$3
    local executor_image=$4

    cat <<EOF  >$DOCKERIGNOREFILE
**/__pycache__
*.pyc
EOF
    cat <<EOF  >$DOCKERFILE
FROM $from_image AS ${executor_class}-executor-image
LABEL Description="FD.io CI '$executor_class' executor docker image for $executor_os_name/$OS_ARCH"
LABEL Vendor="fd.io"
LABEL Version="$DOCKER_TAG"
EOF
    ${executor_class}_generate_apt_dockerfile $executor_class \
        $executor_os_name $executor_image
}
