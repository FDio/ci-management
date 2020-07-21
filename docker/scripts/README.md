# Automated building of FD.io CI docker 'builder' images

This collection of bash scripts and libraries are used to automate the process
of building FD.io docker 'builder' images (aka Nomad executors). The goal is to
create a completely automated CI/CD pipeline. The bash code is designed to be
run in a regular Linux bash shell in order to bootstrap the CI/CD pipeline
 as well as in a docker 'builder' image started by a ci-management jenkins job.

## Bash Libraries (*_lib.sh)

The bash libraries are designed to be sourced both inside of the docker build
environment (e.g. from a script invoked in a Dockerfile RUN statement) as well
as in a normal Linux shell.

- apt_lib.sh:     Dockerfile generation functions for OS's using apt (e.g. ubuntu)
- common_lib.sh:  Common utility functions and environment variables
- csit_lib.sh:    CSIT specific functions and environment variables
- vpp_lib.sh:     VPP specific functions and environment variables
- yum_lib.sh:     Dockerfile generation functions for OS's using yum (e.g. centos)

## Bash Scripts

There are two types of bash scripts, those intended to be run solely inside
the docker build execution environment, the other run either inside or
outside of it.

### Inside Docker Build Bash Scripts

The scripts that must be run inside the 'docker build' environment are
generally per-project scripts for either installing OS packages or
populating the pip cache.

- csit_pip_cache.sh:         Run 'pip install -r <requirements files>' for CSIT branches supported by builder image
- vpp_install_packages.sh    Install OS packages (e.g. 'make install-dep') for VPP branches suported by builder image
- vpp_pip_cache.sh           Run 'pip install -r <requirements files>' for VPP branches supported by builder image

### General Purpose Bash Scripts

These scripts are used to implement the process and inspect the results.

- create_docker_builder_image.sh:  Builder script to create one or more builder images.
- dump_build_logs.sh:              Find warnings/errors in the build logs and dump the create_docker_builder_image.sh execution log.

## Running The Scripts

### Bootstrapping The Builder Images

The following commands are useful to build the initial builder images:

On x86_64 host:
export CIMAN_ROOT=/scratch/docker-build/ci-management && sudo -E $CIMAN_ROOT/docker/scripts/create_docker_builder_image.sh ubuntu-18.04 2>&1 | tee u1804-x86_64.log | grep -ve '^+'
export CIMAN_ROOT=/scratch/docker-build/ci-management && sudo -E $CIMAN_ROOT/docker/scripts/create_docker_builder_image.sh centos-7 2>&1 | tee centos7-x86_64.log | grep -ve '^+'

On aarch64 host:
export CIMAN_ROOT=/scratch/docker-build/ci-management && sudo -E $CIMAN_ROOT/docker/scripts/create_docker_builder_image.sh ubuntu-18.04 2>&1 | tee u1804-aarch64.log | grep -ve '^+'
export CIMAN_ROOT=/scratch/docker-build/ci-management && sudo -E $CIMAN_ROOT/docker/scripts/create_docker_builder_image.sh centos-7 2>&1 | tee centos7-aarch64.log | grep -ve '^+'

### Building in a Builder Image

By running the docker image with docker socket mounted in the container,
the docker build environment runs on the host's docker daemon.  This
avoids the pitfalls encountered with Docker-In-Docker environments:

  sudo docker run -it -v /var/run/docker.sock:/var/run/docker.sock <docker-image>

The environment in the docker shell contains all of the necessary
environment variable definitions so the docker scripts can be run
directly on the cli:

  create_docker_builder_image.sh ubuntu-18.04 centos-7

