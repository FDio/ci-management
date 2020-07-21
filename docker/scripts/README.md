# Automated building of FD.io CI docker 'builder' images

This collection of bash scripts and libraries are used to automate the process
of building FD.io docker 'builder' images (aka Nomad executors). The goal is to
create a completely automated CI/CD pipeline. The bash code is designed to be
run in a regular Linux bash shell in order to bootstrap the CI/CD pipeline
as well as in a docker 'builder' image started by a ci-management jenkins job.
The Dockerfile is generated prior to executing 'docker build' based on the os
parameter specified.  The project git repos are also copied into the docker
container and retained for optimization of git object retrieval by the Jenkins
jobs running the CI/CD tasks.

## Bash Libraries (lib_*.sh)

The bash libraries are designed to be sourced both inside of the docker build
environment (e.g. from a script invoked in a Dockerfile RUN statement) as well
as in a normal Linux shell.

- lib_apt.sh:     Dockerfile generation functions apt package manager.
- lib_common.sh:  Common utility functions and environment variables
- lib_csit.sh:    CSIT specific functions and environment variables
- lib_vpp.sh:     VPP specific functions and environment variables
- lib_yum.sh:     Dockerfile generation functions yum package manager.

## Bash Scripts

There are two types of bash scripts, those intended to be run solely inside
the docker build execution environment, the other run either inside or
outside of it.

### Inside Docker Build Bash Scripts

The scripts that must be run inside the 'docker build' environment are
generally per-project scripts for either installing OS and python packages.
The latter are not retained but installing the python packages populates the
pip/http caches so that packages are installed from the cache files in the
docker container.

- vpp_install_packages.sh:   Install OS and python packages for VPP branches
- csit_install_packages.sh:  Install OS and python packages for CSIT branches

### General Purpose Bash Scripts

These scripts are used to implement the process and inspect the results.

- create_docker_builder_image.sh:  Builder script to create one or more builder images.
- dump_build_logs.sh:              Find warnings/errors in the build logs and dump the create_docker_builder_image.sh execution log.

## Running The Scripts

### Bootstrapping The Builder Images

The following commands are useful to build the initial builder images:

cd <ci-managment repol>
sudo -E ./docker/scripts/create_docker_builder_image.sh ubuntu-18.04 2>&1 | tee u1804-$(uname -m).log | grep -ve '^+'
sudo -E ./docker/scripts/create_docker_builder_image.sh centos-7 2>&1 | tee centos7-$(uname -m).log | grep -ve '^+'


### Building in a Builder Image

By running the docker image with docker socket mounted in the container,
the docker build environment runs on the host's docker daemon.  This
avoids the pitfalls encountered with Docker-In-Docker environments:

sudo docker run -it -v /var/run/docker.sock:/var/run/docker.sock <docker-image>

The environment in the docker shell contains all of the necessary
environment variable definitions so the docker scripts can be run
directly on the cli:

create_docker_builder_image.sh ubuntu-18.04 centos-7

# Script Workflow

TBD.

# DockerHub Repository & Docker Image Tag Nomenclature:

## DockerHub Repositories

- fdiotools/builder-ubuntu18.04
- fdiotools/builder-ubuntu20.04
- fdiotools/builder-centos7
- fdiotools/builder-centos8
- fdiotools/builder-debian9
- fdiotools/csit-ubuntu18.04

## Docker Image Tags

- prod-x86_64
- prod-aarch64
- sandbox-x86_64
- sandbox-aarch64
- test-x86_64
- test-aarch64

# Jenkins-Nomad Label Definitions

<class>-<os>-<role>-<arch>  (e.g. builder-prod-ubuntu18.04-x86_64)

- class
-- builder
-- csit

- role
-- prod
-- test
-- sandbox

- os
-- ubuntu18.04
-- centos7
-- ubuntu20.04
-- centos8
-- debian9

- arch
-- x86_64
-- aarch64

## Jenkins Nomad Plugin Node Labels

### Common Attributes of All Jenkins Nomad Plugin Nodes
- Disk: 3000
- Priority: 50
- Idle Termination Time: 10
- Executors: 1
- Usage: Only build jobs with label expressions matching this node
- Workspace root: /w
- Privileged: Y
- Network: bridge
- Force-pull: Y

### Production (prod) Jenkins Nomad Plugin Nodes

#### Node 'builder-ubuntu18.04-prod-x86_64'
- Labels: builder-ubuntu18.04-prod-x86_64
- Job Prefix: builder-ubuntu18.04-prod-x86_64
- Image: fdiotools/builder-ubuntu18.04:prod-x86_64
- CPU: 14000
- Memory: 14000
- ${attr.cpu.arch}: amd64
- ${node.class}: builder

#### Node 'builder-ubuntu18.04-prod-aarch64'
- Labels: builder-ubuntu18.04-prod-aarch64
- Job Prefix: builder-ubuntu18.04-prod-aarch64
- Image: fdiotools/builder-ubuntu18.04:prod-aarch64
- CPU: 6000
- Memory: 10000
- ${attr.cpu.arch}: arm64
- ${node.class}: builder

#### Node 'builder-centos7-prod-x86_64'
- Labels: builder-centos7-prod-x86_64
- Job Prefix: builder-centos7-prod-x86_64
- Image: fdiotools/builder-centos7:prod-x86_64
- CPU: 14000
- Memory: 14000
- ${attr.cpu.arch}: amd64
- ${node.class}: builder

#### Node 'builder-centos7-prod-aarch64'
- Labels: builder-centos7-prod-aarch64
- Job Prefix: builder-centos7-prod-aarch64
- Image: fdiotools/builder-centos7:prod-aarch64
- CPU: 6000
- Memory: 10000
- ${attr.cpu.arch}: arm64
- ${node.class}: builder

#### Node 'builder-ubuntu20.04-prod-x86_64'
- Labels: builder-ubuntu20.04-prod-x86_64
- Job Prefix: builder-ubuntu20.04-prod-x86_64
- Image: fdiotools/builder-ubuntu20.04:prod-x86_64
- CPU: 14000
- Memory: 14000
- ${attr.cpu.arch}: amd64
- ${node.class}: builder

#### Node 'builder-ubuntu20.04-prod-aarch64'
- Labels: builder-ubuntu20.04-prod-aarch64
- Job Prefix: builder-ubuntu20.04-prod-aarch64
- Image: fdiotools/builder-ubuntu20.04:prod-aarch64
- CPU: 6000
- Memory: 10000
- ${attr.cpu.arch}: arm64
- ${node.class}: builder

#### Node 'builder-centos8-prod-x86_64'
- Labels: builder-centos8-prod-x86_64
- Job Prefix: builder-centos7-prod-x86_64
- Image: fdiotools/builder-centos8:prod-x86_64
- CPU: 14000
- Memory: 14000
- ${attr.cpu.arch}: amd64
- ${node.class}: builder

#### Node 'builder-centos8-prod-aarch64'
- Labels: builder-centos8-prod-aarch64
- Job Prefix: builder-centos8-prod-aarch64
- Image: fdiotools/builder-centos8:prod-aarch64
- CPU: 6000
- Memory: 10000
- ${attr.cpu.arch}: arm64
- ${node.class}: builder

#### Node 'builder-debian9-prod-x86_64'
- Labels: builder-debian9-prod-x86_64
- Job Prefix: builder-debian9-prod-x86_64
- Image: fdiotools/builder-debian9:prod-x86_64
- CPU: 14000
- Memory: 14000
- ${attr.cpu.arch}: amd64
- ${node.class}: builder

#### Node 'builder-debian9-prod-aarch64'
- Labels: builder-debian9-prod-aarch64
- Job Prefix: builder-debian9-prod-aarch64
- Image: fdiotools/builder-debian9:prod-aarch64
- CPU: 6000
- Memory: 10000
- ${attr.cpu.arch}: arm64
- ${node.class}: builder

### Sandbox (sandbox) Jenkins Nomad Plugin Nodes

#### Node 'builder-ubuntu18.04-sandbox-x86_64'
- Labels: builder-ubuntu18.04-sandbox-x86_64
- Job Prefix: builder-ubuntu18.04-sandbox-x86_64
- Image: fdiotools/builder-ubuntu18.04:sandbox-x86_64
- CPU: 14000
- Memory: 14000
- ${attr.cpu.arch}: amd64
- ${node.class}: builder

#### Node 'builder-ubuntu18.04-sandbox-aarch64'
- Labels: builder-ubuntu18.04-sandbox-aarch64
- Job Prefix: builder-ubuntu18.04-sandbox-aarch64
- Image: fdiotools/builder-ubuntu18.04:sandbox-aarch64
- CPU: 6000
- Memory: 10000
- ${attr.cpu.arch}: arm64
- ${node.class}: builder

#### Node 'builder-centos7-sandbox-x86_64'
- Labels: builder-centos7-sandbox-x86_64
- Job Prefix: builder-centos7-sandbox-x86_64
- Image: fdiotools/builder-centos7:sandbox-x86_64
- CPU: 14000
- Memory: 14000
- ${attr.cpu.arch}: amd64
- ${node.class}: builder

#### Node 'builder-centos7-sandbox-aarch64'
- Labels: builder-centos7-sandbox-aarch64
- Job Prefix: builder-centos7-sandbox-aarch64
- Image: fdiotools/builder-centos7:sandbox-aarch64
- CPU: 6000
- Memory: 10000
- ${attr.cpu.arch}: arm64
- ${node.class}: builder

#### Node 'builder-ubuntu20.04-sandbox-x86_64'
- Labels: builder-ubuntu20.04-sandbox-x86_64
- Job Prefix: builder-ubuntu20.04-sandbox-x86_64
- Image: fdiotools/builder-ubuntu20.04:sandbox-x86_64
- CPU: 14000
- Memory: 14000
- ${attr.cpu.arch}: amd64
- ${node.class}: builder

#### Node 'builder-ubuntu20.04-sandbox-aarch64'
- Labels: builder-ubuntu20.04-sandbox-aarch64
- Job Prefix: builder-ubuntu20.04-sandbox-aarch64
- Image: fdiotools/builder-ubuntu20.04:sandbox-aarch64
- CPU: 6000
- Memory: 10000
- ${attr.cpu.arch}: arm64
- ${node.class}: builder

#### Node 'builder-centos8-sandbox-x86_64'
- Labels: builder-centos8-sandbox-x86_64
- Job Prefix: builder-centos8-sandbox-x86_64
- Image: fdiotools/builder-centos8:sandbox-x86_64
- CPU: 14000
- Memory: 14000
- ${attr.cpu.arch}: amd64
- ${node.class}: builder

#### Node 'builder-centos8-sandbox-aarch64'
- Labels: builder-centos8-sandbox-aarch64
- Job Prefix: builder-centos8-sandbox-aarch64
- Image: fdiotools/builder-centos8:sandbox-aarch64
- CPU: 6000
- Memory: 10000
- ${attr.cpu.arch}: arm64
- ${node.class}: builder

#### Node 'builder-debian9-sandbox-x86_64'
- Labels: builder-debian9-sandbox-x86_64
- Job Prefix: builder-debian9-sandbox-x86_64
- Image: fdiotools/builder-debian9:sandbox-x86_64
- CPU: 14000
- Memory: 14000
- ${attr.cpu.arch}: amd64
- ${node.class}: builder

#### Node 'builder-debian9-sandbox-aarch64'
- Labels: builder-debian9-sandbox-aarch64
- Job Prefix: builder-debian9-sandbox-aarch64
- Image: fdiotools/builder-debian9:sandbox-aarch64
- CPU: 6000
- Memory: 10000
- ${attr.cpu.arch}: arm64
- ${node.class}: builder

### Automated Testing (test) Jenkins Nomad Plugin Nodes

#### Node 'builder-ubuntu18.04-test-x86_64'
- Labels: builder-ubuntu18.04-test-x86_64
- Job Prefix: builder-ubuntu18.04-test-x86_64
- Image: fdiotools/builder-ubuntu18.04:test-x86_64
- CPU: 14000
- Memory: 14000
- ${attr.cpu.arch}: amd64
- ${node.class}: builder

#### Node 'builder-ubuntu18.04-test-aarch64'
- Labels: builder-ubuntu18.04-test-aarch64
- Job Prefix: builder-ubuntu18.04-test-aarch64
- Image: fdiotools/builder-ubuntu18.04:test-aarch64
- CPU: 6000
- Memory: 10000
- ${attr.cpu.arch}: arm64
- ${node.class}: builder

#### Node 'builder-centos7-test-x86_64'
- Labels: builder-centos7-test-x86_64
- Job Prefix: builder-centos7-test-x86_64
- Image: fdiotools/builder-centos7:test-x86_64
- CPU: 14000
- Memory: 14000
- ${attr.cpu.arch}: amd64
- ${node.class}: builder

#### Node 'builder-centos7-test-aarch64'
- Labels: builder-centos7-test-aarch64
- Job Prefix: builder-centos7-test-aarch64
- Image: fdiotools/builder-centos7:test-aarch64
- CPU: 6000
- Memory: 10000
- ${attr.cpu.arch}: arm64
- ${node.class}: builder

#### Node 'builder-ubuntu20.04-test-x86_64'
- Labels: builder-ubuntu20.04-test-x86_64
- Job Prefix: builder-ubuntu20.04-test-x86_64
- Image: fdiotools/builder-ubuntu20.04:test-x86_64
- CPU: 14000
- Memory: 14000
- ${attr.cpu.arch}: amd64
- ${node.class}: builder

#### Node 'builder-ubuntu20.04-test-aarch64'
- Labels: builder-ubuntu20.04-test-aarch64
- Job Prefix: builder-ubuntu20.04-test-aarch64
- Image: fdiotools/builder-ubuntu20.04:test-aarch64
- CPU: 6000
- Memory: 10000
- ${attr.cpu.arch}: arm64
- ${node.class}: builder

#### Node 'builder-centos8-test-x86_64'
- Labels: builder-centos8-test-x86_64
- Job Prefix: builder-centos8-test-x86_64
- Image: fdiotools/builder-centos8:test-x86_64
- CPU: 14000
- Memory: 14000
- ${attr.cpu.arch}: amd64
- ${node.class}: builder

#### Node 'builder-centos8-test-aarch64'
- Labels: builder-centos8-test-aarch64
- Job Prefix: builder-centos8-test-aarch64
- Image: fdiotools/builder-centos8:test-aarch64
- CPU: 6000
- Memory: 10000
- ${attr.cpu.arch}: arm64
- ${node.class}: builder

#### Node 'builder-debian9-test-x86_64'
- Labels: builder-debian9-test-x86_64
- Job Prefix: builder-debian9-test-x86_64
- Image: fdiotools/builder-debian9:test-x86_64
- CPU: 14000
- Memory: 14000
- ${attr.cpu.arch}: amd64
- ${node.class}: builder

#### Node 'builder-debian9-test-aarch64'
- Labels: builder-debian9-test-aarch64
- Job Prefix: builder-debian9-test-aarch64
- Image: fdiotools/builder-debian9:test-aarch64
- CPU: 6000
- Memory: 10000
- ${attr.cpu.arch}: arm64
- ${node.class}: builder
