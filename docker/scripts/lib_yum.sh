# lib_yum.sh - Docker build script yum library.
#              For import only.

# Don't import more than once.
if [ -n "$(alias lib_yum_imported 2> /dev/null)" ] ; then
  return 0
fi
alias lib_yum_imported=true

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. $CIMAN_DOCKER_SCRIPTS/lib_common.sh

dump_yum_package_list() {
  branchname="$(echo $branch | sed -e 's,/,_,')"
  yum list installed > \
    "$DOCKER_BUILD_LOG_DIR/$FDIOTOOLS_IMAGENAME-$branchname-yum-packages.log"
}

yum_install_packages() {
  yum install -y $@
}

yum_install_docker_os_package_dependancies() {
  yum_install_packages yum-utils
}

yum_install_docker() {
  yum-config-manager --add-repo \
    https://download.docker.com/linux/${OS_ID}/docker-ce.repo
  yum-config-manager --enablerepo=docker-ce-stable
  yum_install_packages docker-ce docker-ce-cli containerd.io
}

generate_yum_dockerfile() {
  local builder_os_name=$1
  local from_image=$2
  local builder_image=$3
  local from_image_os_id="$(echo $from_image | cut -d: -f2)"
  
  cat <<EOF >$DOCKERFILE
FROM $from_image AS image-builder
LABEL Description="FD.io CI builder docker image for $builder_os_name/$OS_ARCH"
LABEL Vendor="fd.io"
LABEL Version="$DOCKER_TAG"

# Build Environment Variables
ENV FDIOTOOLS_IMAGE=$builder_image
ENV LC_ALL=en_US.UTF-8
ENV CIMAN_ROOT="$DOCKER_CIMAN_ROOT"
ENV PATH=$PATH:$DOCKER_CIMAN_ROOT/docker/scripts

# Copy-in build tree containing
# ci-management, vpp, & csit git repos
WORKDIR $DOCKER_BUILD_DIR
COPY . .

# Install baseline packages (minimum build & utils).
#
# ci-management global-jjb requirements:
#   for lf-env.sh:
#       facter
#   from global-jjb/packer/provision/baseline.sh:
#       deltarpm
#       unzip
#       xz
#       puppet
#       python3-pip
#       git
#       git-review
#       perl-XML-XPath
#       make
#       wget
#
# TODO: Fix broken project requirement install targets
#
#   graphviz           for 'make bootstrap-doxygen' (VPP)
#   doxygen            for 'make doxygen' (VPP)
#   enchant            for 'make docs' (VPP)
#   libffi-devel       for python cffi install (Ubuntu20.04/VPP/aarch64)
#   libpcap-devel      for python pypcap install (CSIT)
#   liblapack-devel    for python numpy/scipy (CSIT/aarch64)
#   libopenblas-devel  for python numpy/scipy (CSIT/aarch64)
#
RUN yum update -y \\
    && yum install -y \\
        epel-release \\
    && yum clean all
RUN yum update -y \\
    && yum install -y \\
        yum-utils \\
        deltarpm \\
        doxygen \\
        enchant \\
        emacs \\
        facter \\
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
        make \\
        mawk \\
        perl \\
        perl-XML-XPath \\
        python3-pip \\
        puppet \\
        rake \\
        ruby-devel \\
        sudo \\
        tree \\
        unzip \\
        vim \\
        wget \\
        xz \\
    && yum clean all

# Install packages for all project branches
#
RUN yum update -y \\
    && install_docker.sh \\
    && vpp_install_packages.sh \\
    && csit_install_packages.sh \\
    && builder_common_init.sh \\
    && yum clean all

# CI Runtime Environment
WORKDIR /
ENV VPP_ZOMBIE_NOCHECK=1
RUN gem install package_cloud \\
    && curl -s https://packagecloud.io/install/repositories/fdio/master/script.rpm.sh | sudo bash

# Clean up
RUN dump_build_logs.sh \\
    && rm -rf /tmp/*
EOF
}
