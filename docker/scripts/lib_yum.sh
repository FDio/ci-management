# lib_yum.sh - Docker build script yum library.
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
if [ -n "$(alias lib_yum_imported 2> /dev/null)" ] ; then
    return 0
fi
alias lib_yum_imported="true"

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. "$CIMAN_DOCKER_SCRIPTS/lib_common.sh"

dump_yum_package_list() {
    branchname="$(echo $branch | sed -e 's,/,_,')"
    yum list installed > \
        "$DOCKER_BUILD_LOG_DIR/$FDIOTOOLS_IMAGENAME-$branchname-yum-packages.log"
}

yum_install_packages() {
    yum install -y "$@"
}

generate_yum_dockerfile_common() {
    local executor_class="$1"
    local executor_image="$2"

    cat <<EOF >>"$DOCKERFILE"

# Create download dir to cache external tarballs
WORKDIR $DOCKER_DOWNLOADS_DIR

# Copy-in temporary build tree containing
# ci-management, vpp, & csit git repos
WORKDIR $DOCKER_BUILD_DIR
COPY . .

# Build Environment Variables
ENV FDIOTOOLS_IMAGE=$executor_image
ENV FDIOTOOLS_EXECUTOR_CLASS=$executor_class
ENV CIMAN_ROOT="$DOCKER_CIMAN_ROOT"
ENV PATH=$PATH:$DOCKER_CIMAN_ROOT/docker/scripts
ENV LF_VENV="/root/lf-venv"

# Configure locales
ENV LANG=en_US.UTF-8 LANGUAGE=en_US LC_ALL=en_US.UTF-8

# Install baseline packages (minimum build & utils).
#
# ci-management global-jjb requirements:
#    for lftools:
#        libxml2-devel
#        libxslt-devel
#        xmlstarlet
#    for lf-env.sh:
#        facter
#   from packer/provision/baseline.sh:
#        deltarpm
#        unzip
#        xz
#        python3-pip
#        git
#        git-review
#        perl-XML-XPath
#        make
#        wget
#
# TODO:  Fix broken project requirement install targets
#        graphviz           for 'make bootstrap-doxygen' (VPP)
#        doxygen            for 'make doxygen' (VPP)
#        enchant            for 'make docs' (VPP)
#        libffi-devel       for python cffi install (Ubuntu20.04/VPP/aarch64)
#        libpcap-devel      for python pypcap install (CSIT)
#        liblapack-devel    for python numpy/scipy (CSIT/aarch64)
#        libopenblas-devel  for python numpy/scipy (CSIT/aarch64)
#        sshpass            for CSIT
#
RUN yum update -y \\
  && yum install -y epel-release \\
  && yum clean all
RUN yum install -y \\
        yum-utils \\
        bind-utils \\
        deltarpm \\
        doxygen \\
        enchant \\
        emacs \\
        facter \\
        gdb \\
        git \\
        git-review \\
        graphviz \\
        iproute \\
        java-1.8.0-openjdk \\
        java-1.8.0-openjdk-devel \\
        jq \\
        libffi-devel \\
        liblapack-devel \\
        libopenblas-devel \\
        libpcap-devel \\
        libxml2-devel \\
        libxslt-devel \\
        make \\
        mawk \\
        perl \\
        perl-XML-XPath \\
        python3-pip \\
        rake \\
        ruby-devel \\
        sshpass \\
        sudo \\
        tree \\
        unzip \\
        vim \\
        wget \\
        xmlstarlet \\
        xz \\
  && curl -s https://packagecloud.io/install/repositories/fdio/master/script.rpm.sh | bash \\
  && curl -fsSL https://get.docker.com | sh \\
  && yum clean all

# Install packages for all project branches
#
RUN dbld_vpp_install_packages.sh \\
  && dbld_csit_install_packages.sh \\
  && yum clean all
EOF
}

generate_yum_dockerfile_clean() {
    cat <<EOF >>"$DOCKERFILE"

# Clean up
RUN dbld_dump_build_logs.sh \\
  && rm -rf "/tmp/*"
EOF
}

builder_generate_yum_dockerfile() {
    local executor_class="$1"
    local executor_os_name="$2"
    local from_image="$3"
    local executor_image="$4"

    generate_yum_dockerfile_common "$executor_class" "$executor_image"
    cat <<EOF >>"$DOCKERFILE"

# Install LF-IT requirements
RUN dbld_lfit_requirements.sh \\
  && yum clean all

# CI Runtime Environment
WORKDIR /
ENV VPP_ZOMBIE_NOCHECK="1"
RUN gem install package_cloud \\
  && curl -s https://packagecloud.io/install/repositories/fdio/master/script.rpm.sh | bash

# TODO: Mount ccache volume into docker container, then remove this.
ENV CCACHE_DISABLE="1"
EOF
    generate_yum_dockerfile_clean
}

csit_generate_yum_dockerfile() {
    echo_log "ERROR: ${FUNCNAME[0]} TBD!"
    exit 1
}

csit_dut_generate_yum_dockerfile() {
    echo_log "ERROR: ${FUNCNAME[0]} TBD!"
    exit 1
}

csit_shim_generate_yum_dockerfile() {
    echo_log "ERROR: ${FUNCNAME[0]} TBD!"
    exit 1
}

generate_yum_dockerfile() {
    local executor_class="$1"
    local executor_os_name="$2"
    local from_image="$3"
    local executor_image="$4"

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
    ${executor_class}_generate_yum_dockerfile "$executor_class" \
        "$executor_os_name" "$from_image" "$executor_image"
}
