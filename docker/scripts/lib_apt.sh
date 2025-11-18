# lib_apt.sh - Docker build script apt library.
#              For import only.

# Copyright (c) 2024 Cisco and/or its affiliates.
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

select_dind_image() {
    local input_image="$1"

    case "$input_image" in
        "ubuntu:22.04")
            echo "cruizba/ubuntu-dind:jammy-29.0.0|true"
            ;;
        "ubuntu:24.04")
            echo "cruizba/ubuntu-dind:noble-29.0.0|true"
            ;;
        *)
            echo "$input_image|false"
            ;;
    esac
}

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. "$CIMAN_DOCKER_SCRIPTS/lib_common.sh"
. "$CIMAN_DOCKER_SCRIPTS/lib_csit.sh"

dump_apt_package_list() {
    branchname="$(echo $branch | sed -e 's,/,_,')"
    dpkg -l > \
         "$DOCKER_BUILD_LOG_DIR/$FDIOTOOLS_IMAGENAME-$branchname-apt-packages.log"
}

apt_install_packages() {
    apt-get install -y --allow-downgrades --allow-remove-essential \
            --allow-change-held-packages $@
}

generate_apt_dockerfile_common() {
    local executor_class="$1"
    local executor_image="$2"
    local dpkg_arch="$(dpkg --print-architecture)"

    cat <<EOF >>"$DOCKERFILE"

# Create download dir to cache external tarballs
WORKDIR $DOCKER_DOWNLOADS_DIR

# Copy-in temporary build tree containing
# ci-management, vpp, & csit git repos
WORKDIR $DOCKER_BUILD_DIR
COPY . .

# Build Environment Variables
ENV DEBIAN_FRONTEND="noninteractive"
ENV FDIOTOOLS_IMAGE="$executor_image"
ENV FDIOTOOLS_EXECUTOR_CLASS="$executor_class"
ENV CIMAN_ROOT="$DOCKER_CIMAN_ROOT"
ENV PATH="\$PATH:$DOCKER_CIMAN_ROOT/docker/scripts"

# Configure locales
RUN apt-get update -qq \\
  && apt-get install -y \\
        apt-utils \\
        locales \\
  && sed -i 's/# \(en_US\.UTF-8 .*\)/\1/' /etc/locale.gen \\
  && locale-gen en_US.UTF-8 \\
  && dpkg-reconfigure --frontend=noninteractive locales \\
  && update-locale LANG=en_US.UTF-8 \\
  && TZ=Etc/UTC && ln -snf /usr/share/zoneinfo/\$TZ /etc/localtime && echo \$TZ > /etc/timezone \\
  && rm -r /var/lib/apt/lists/*
ENV LANG="en_US.UTF-8" LANGUAGE="en_US" LC_ALL="en_US.UTF-8"

# Install baseline packages (minimum build & utils).
#
# ci-management global-jjb requirements:
#        facter
#        python3-pip
#        python3-venv
#    for lftools:
#        xmlstarlet
#        libxml2-dev
#        libxslt-dev
#   from packer/provision/baseline.sh:
#        unzip
#        xz-utils
#        git
#        git-review
#        libxml2-dev
#        libxml-xpath-perl
#        libxslt-dev
#        make
#        wget
#        jq
#
# Python build from source requirements:
#        build-essential
#
# TODO:  Fix broken project requirement install targets
#        graphviz         for doxygen (HICN)
#        doxygen          for doxygen (HICN)
#        libffi-dev       for python cffi install (Ubuntu24.04/VPP/aarch64)
#        liblapack-dev    for python numpy/scipy (CSIT/aarch64)
#        libopenblas-dev  for python numpy/scipy (CSIT/aarch64)
#        libpcap-dev      for python pypcap install (CSIT)
#        sshpass          for CSIT jobs
#
RUN apt-get update -qq \\
  && apt-get install -y \\
             apt-transport-https \\
             curl \\
             ca-certificates \\
             default-jdk \\
             default-jre \\
             dnsutils \\
             doxygen \\
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
             libxml-xpath-perl \\
             make \\
             python3-pip \\
             python3-venv \\
             python3-virtualenv \\
             rsync \\
             ruby-dev \\
             software-properties-common \\
             sshpass \\
             sysstat \\
             sudo \\
             traceroute \\
             tree \\
             vim \\
             wget \\
             xmlstarlet \\
             xz-utils \\
  && curl -L https://packagecloud.io/fdio/master/gpgkey | apt-key add - \\
  && curl -s https://packagecloud.io/install/repositories/fdio/master/script.deb.sh | bash \\
  && rm -r /var/lib/apt/lists/*

# Install terraform for CSIT
#
RUN wget https://releases.hashicorp.com/terraform/1.7.3/terraform_1.7.3_linux_$dpkg_arch.zip \\
  && unzip terraform_1.7.3_linux_$dpkg_arch.zip \\
  && mv terraform /usr/bin \\
  && rm -f terraform_1.7.3_linux_$dpkg_arch.zip
EOF

    generate_apt_dockerfile_install_golang

    cat <<EOF >>"$DOCKERFILE"

# Install packages for all project branches
#
RUN apt-get update -qq \\
  && dbld_vpp_install_packages.sh \\
  && dbld_csit_install_packages.sh \\
  && apt-get install -y pkg-config \\
  && rm -r /var/lib/apt/lists/*
EOF
}

generate_apt_dockerfile_clean() {
    cat <<EOF >>"$DOCKERFILE"

# Clean up copy-in build tree
RUN dbld_dump_build_logs.sh \\
  && apt-get -y autoremove \\
  && rm -rf "/tmp/*" "$DOCKER_BUILD_FILES_DIR" "/root/.ccache"
EOF
}

generate_apt_dockerfile_install_golang() {
    local go_tarball_arch="amd64"

    if [ "$OS_ARCH" = "aarch64" ] ; then
        go_tarball_arch="arm64"
    fi

    cat <<EOF >>"$DOCKERFILE"

# Install golang for HostStack Test (HST) jobs
#
ENV GOPATH /go
ENV GOROOT /usr/local/go
ENV PATH \$GOPATH/bin:/usr/local/go/bin:\$PATH
RUN rm -rf /usr/local/go /usr/bin/go \\
    && wget -P /tmp "https://go.dev/dl/go${DOCKER_GOLANG_VERSION}.linux-${go_tarball_arch}.tar.gz" \\
    && tar -C /usr/local -xzf "/tmp/go${DOCKER_GOLANG_VERSION}.linux-${go_tarball_arch}.tar.gz" \\
    && rm "/tmp/go${DOCKER_GOLANG_VERSION}.linux-${go_tarball_arch}.tar.gz" \\
    && ln -s /usr/local/go/bin/go /usr/bin/go \\
    && echo -n "\nGOPATH=\$GOPATH\nGOROOT=\$GOROOT" | tee -a /etc/environment \\
    && mkdir -p "\$GOPATH/src" "\$GOPATH/bin" && chmod -R 777 "\$GOPATH"
EOF
}

# Generate 'builder' class apt dockerfile
builder_generate_apt_dockerfile() {
    local executor_class="$1"
    local executor_os_name="$2"
    local executor_image="$3"
    local vpp_install_skip_sysctl_envvar="";

    generate_apt_dockerfile_common "$executor_class" "$executor_image"
    csit_builder_generate_docker_build_files
    cat <<EOF >>"$DOCKERFILE"

# Install LF-IT requirements
ENV LF_VENV="/root/lf-venv"
RUN apt-get update -qq \\
  && dbld_lfit_requirements.sh \\
  && rm -r /var/lib/apt/lists/*

# Install packagecloud requirements
RUN gem install rake package_cloud \\
  && curl -s https://packagecloud.io/install/repositories/fdio/master/script.deb.sh | bash

# Install CSIT ssh requirements
# TODO: Verify why badkey is required & figure out how to avoid it.
COPY files/badkey /root/.ssh/id_rsa
COPY files/sshconfig /root/.ssh/config

# CI Runtime Environment
WORKDIR /
$vpp_install_skip_sysctl_envvar
ENV VPP_ZOMBIE_NOCHECK="1"
ENV CCACHE_DIR="/scratch/ccache"
ENV CCACHE_MAXSIZE="10G"
EOF
    generate_apt_dockerfile_clean
}

# Generate 'csit_dut' class apt dockerfile
csit_dut_generate_apt_dockerfile() {
    local executor_class="$1"
    local executor_os_name="$2"
    local executor_image="$3"

    csit_dut_generate_docker_build_files
    generate_apt_dockerfile_common "$executor_class" "$executor_image"
    cat <<EOF >>"$DOCKERFILE"

# Install csit_dut specific packages
RUN apt-get update -qq \\
  && apt-get install -y \\
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
RUN mkdir -p /var/run/sshd

# SSH settings
RUN echo 'root:Csit1234' | chpasswd \\
  && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \\
  && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

EXPOSE 2222

COPY files/supervisord.conf /etc/supervisor/supervisord.conf

CMD ["sh", "-c", "rm -f /dev/shm/db /dev/shm/global_vm /dev/shm/vpe-api; /usr/bin/supervisord -c /etc/supervisor/supervisord.conf; /usr/sbin/sshd -D -p 2222"]
EOF
    generate_apt_dockerfile_clean
}

# Generate 'csit_shim' class apt dockerfile
csit_shim_generate_apt_dockerfile() {
    local executor_class="$1"
    local executor_os_name="$2"
    local executor_image="$3"

    csit_shim_generate_docker_build_files
    cat <<EOF >>"$DOCKERFILE"

# Copy-in temporary build tree containing
# ci-management, vpp, & csit git repos
WORKDIR $DOCKER_BUILD_DIR
COPY . .

# Build Environment Variables
ENV DEBIAN_FRONTEND="noninteractive"
ENV FDIOTOOLS_IMAGE="$executor_image"
ENV FDIOTOOLS_EXECUTOR_CLASS="$executor_class"
ENV CIMAN_ROOT="$DOCKER_CIMAN_ROOT"
ENV PATH="\$PATH:$DOCKER_CIMAN_ROOT/docker/scripts"

# Configure locales & timezone
RUN apt-get update -qq \\
  && apt-get install -y \\
             apt-utils \\
             locales \\
  && sed -i 's/# \(en_US\.UTF-8 .*\)/\1/' /etc/locale.gen \\
  && locale-gen en_US.UTF-8 \\
  && dpkg-reconfigure --frontend=noninteractive locales \\
  && update-locale LANG=en_US.UTF-8 \\
  && TZ=Etc/UTC && ln -snf /usr/share/zoneinfo/\$TZ /etc/localtime && echo \$TZ > /etc/timezone \\
  && rm -r /var/lib/apt/lists/*
ENV LANG=en_US.UTF-8 LANGUAGE=en_US LC_ALL=en_US.UTF-8

COPY files/wrapdocker /usr/local/bin/wrapdocker
RUN chmod +x /usr/local/bin/wrapdocker

# Install packages and Docker
RUN apt-get update -qq \\
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

# TODO: Verify why badkeypub is required & figure out how to avoid it.
COPY files/badkeypub /root/.ssh/authorized_keys
COPY files/sshconfig /root/.ssh/config

# Clean up copy-in build tree
RUN rm -rf /tmp/* $DOCKER_BUILD_FILES_DIR

# Start sshd by default
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
EOF
}

generate_apt_dockerfile() {
    local executor_class="$1"
    local executor_os_name="$2"
    local from_image="$3"
    local executor_image="$4"
    local is_dind_image="false"

    # TODO: Enable HST on AARCH64 when supported in vpp/extras/hs-test
    IFS="|" read -r from_image is_dind_image <<< "$(select_dind_image "$from_image")"

    cat <<EOF  >"$DOCKERIGNOREFILE"
**/__pycache__
*.pyc
EOF
    cat <<EOF  >"$DOCKERFILE"
FROM $from_image AS ${executor_class}-executor-image
LABEL Description="FD.io CI '$executor_class' executor docker image for $executor_os_name/$OS_ARCH"
LABEL Vendor="fd.io"
LABEL Version="$DOCKER_TAG"
EOF
    if [ "$is_dind_image" = "true" ] ; then
        cat <<EOF >>"$DOCKERFILE"
# Remove extraneous environment variable(s) created in "$from_image"
ENV DEBUG=
EOF
    fi

    "${executor_class}"_generate_apt_dockerfile "$executor_class" \
        "$executor_os_name" "$executor_image"
}
