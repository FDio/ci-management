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

generate_yum_dockerfile() {
  write_yum_docker_gpg_keyfile
  cat <<EOF >$DOCKERFILE
FROM $os_tag AS image-builder
LABEL Description="https://hub.docker.com/u/fdiotools $image builder image"
LABEL Vendor="fd.io"
LABEL Version="$tag"

# Build Environment Variables
ENV FDIOTOOLS_IMAGE=$image
ENV LC_ALL=en_US.UTF-8
ENV CIMAN_ROOT="$DOCKER_CIMAN_ROOT"
ENV PATH=$PATH:$DOCKER_CIMAN_ROOT/docker/scripts

# Copy-in build tree containing
# ci-management, vpp, & csit git repos
WORKDIR $DOCKER_BUILD_DIR
COPY . .

# Install baseline packages (minimum build & utils).
#
# TODO: Fix broken project requirement install targets
#
#   graphviz         for 'make bootstrap-doxygen' (VPP)
#   doxygen          for 'make doxygen' (VPP)
#   enchant          for 'make docs' (VPP)
#   facter           for ci-management/global-jjb scripts
#   libpcap-dev      for python pypcap install (CSIT)
#   liblapack-dev    for python numpy/scipy (CSIT/aarch64)
#   libopenblas-dev  for python numpy/scipy (CSIT/aarch64)
#   python3-pip      for 'make docs-venv' (VPP)
#
RUN yum update -y \\
    && yum install -y \\
        @base https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \\
    && yum clean all
RUN yum update \\
    && yum install -y --enablerepo=epel \\
        yum-utils \\
	doxygen \\
        enchant \\
        emacs \\
        facter \\
        git \\
        graphviz \\
        iproute \\
        java-1.8.0-openjdk \\
        java-1.8.0-openjdk-devel \\
        liblapack-devel \\
        libopenblas-devel \\
        libpcap-devel \\
        make \\
        mawk \\
        perl \\
        python3-pip \\
        rake \\
        ruby-devel \\
        sudo \\
        tree \\
        vim \\
        wget \\
    && yum-config-manager \\
        --add-repo \\
        https://download.docker.com/linux/centos/docker-ce.repo \\
    && rpm --import $DOCKER_YUM_DOCKER_GPGFILE \\
    && yum install -y docker-ce docker-ce-cli containerd.io \\
    && yum clean all

# Install OS packages for project branches
#
RUN builder_common_init.sh \\
    && vpp_install_packages.sh \\
    && csit_install_packages.sh \\
    && yum clean all

# CI Runtime Environment
WORKDIR /
ENV VPP_ZOMBIE_NOCHECK=1
RUN gem install package_cloud \\
    && curl -s https://packagecloud.io/install/repositories/fdio/master/script.rpm.sh | sudo bash

# Clean up
RUN dump_build_logs.sh \\
    && rm -rf /tmp/* $DOCKER_YUM_DOCKER_GPGFILE
EOF
}

write_yum_docker_gpg_keyfile() {
  # To update docker gpg key
  # curl -fsSL https://download.docker.com/linux/centos/gpg
  cat <<EOF >$DOCKER_YUM_DOCKER_GPGFILE
-----BEGIN PGP PUBLIC KEY BLOCK-----

mQINBFit5IEBEADDt86QpYKz5flnCsOyZ/fk3WwBKxfDjwHf/GIflo+4GWAXS7wJ
1PSzPsvSDATV10J44i5WQzh99q+lZvFCVRFiNhRmlmcXG+rk1QmDh3fsCCj9Q/yP
w8jn3Hx0zDtz8PIB/18ReftYJzUo34COLiHn8WiY20uGCF2pjdPgfxE+K454c4G7
gKFqVUFYgPug2CS0quaBB5b0rpFUdzTeI5RCStd27nHCpuSDCvRYAfdv+4Y1yiVh
KKdoe3Smj+RnXeVMgDxtH9FJibZ3DK7WnMN2yeob6VqXox+FvKYJCCLkbQgQmE50
uVK0uN71A1mQDcTRKQ2q3fFGlMTqJbbzr3LwnCBE6hV0a36t+DABtZTmz5O69xdJ
WGdBeePCnWVqtDb/BdEYz7hPKskcZBarygCCe2Xi7sZieoFZuq6ltPoCsdfEdfbO
+VBVKJnExqNZCcFUTEnbH4CldWROOzMS8BGUlkGpa59Sl1t0QcmWlw1EbkeMQNrN
spdR8lobcdNS9bpAJQqSHRZh3cAM9mA3Yq/bssUS/P2quRXLjJ9mIv3dky9C3udM
+q2unvnbNpPtIUly76FJ3s8g8sHeOnmYcKqNGqHq2Q3kMdA2eIbI0MqfOIo2+Xk0
rNt3ctq3g+cQiorcN3rdHPsTRSAcp+NCz1QF9TwXYtH1XV24A6QMO0+CZwARAQAB
tCtEb2NrZXIgUmVsZWFzZSAoQ0UgcnBtKSA8ZG9ja2VyQGRvY2tlci5jb20+iQI3
BBMBCgAhBQJYrep4AhsvBQsJCAcDBRUKCQgLBRYCAwEAAh4BAheAAAoJEMUv62ti
Hp816C0P/iP+1uhSa6Qq3TIc5sIFE5JHxOO6y0R97cUdAmCbEqBiJHUPNQDQaaRG
VYBm0K013Q1gcJeUJvS32gthmIvhkstw7KTodwOM8Kl11CCqZ07NPFef1b2SaJ7l
TYpyUsT9+e343ph+O4C1oUQw6flaAJe+8ATCmI/4KxfhIjD2a/Q1voR5tUIxfexC
/LZTx05gyf2mAgEWlRm/cGTStNfqDN1uoKMlV+WFuB1j2oTUuO1/dr8mL+FgZAM3
ntWFo9gQCllNV9ahYOON2gkoZoNuPUnHsf4Bj6BQJnIXbAhMk9H2sZzwUi9bgObZ
XO8+OrP4D4B9kCAKqqaQqA+O46LzO2vhN74lm/Fy6PumHuviqDBdN+HgtRPMUuao
xnuVJSvBu9sPdgT/pR1N9u/KnfAnnLtR6g+fx4mWz+ts/riB/KRHzXd+44jGKZra
IhTMfniguMJNsyEOO0AN8Tqcl0eRBxcOArcri7xu8HFvvl+e+ILymu4buusbYEVL
GBkYP5YMmScfKn+jnDVN4mWoN1Bq2yMhMGx6PA3hOvzPNsUoYy2BwDxNZyflzuAi
g59mgJm2NXtzNbSRJbMamKpQ69mzLWGdFNsRd4aH7PT7uPAURaf7B5BVp3UyjERW
5alSGnBqsZmvlRnVH5BDUhYsWZMPRQS9rRr4iGW0l+TH+O2VJ8aQ
=0Zqq
-----END PGP PUBLIC KEY BLOCK-----
EOF
}
