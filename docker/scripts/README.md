# Automated Building Of FD.io CI Executor Docker Images

This collection of bash scripts and libraries is used to automate the process
of building FD.io docker 'builder' images (aka Nomad executors). The goal is to
create a completely automated CI/CD pipeline. The bash code is designed to be
run in a regular Linux bash shell in order to bootstrap the CI/CD pipeline
as well as in a docker 'builder' image started by a ci-management jenkins job.
The Dockerfile is generated prior to executing 'docker build' based on the os
parameter specified.  The project git repos are also copied into the docker
container and retained for optimization of git object retrieval by the Jenkins
jobs running the CI/CD tasks.

## Image Builder Algorithm

The general algorithm to automate the generation of the docker images such that
the downloadable requirements for each project are pre-installed or cached in
the executor image is as follows:

1. Run the docker image builder on a host of the target architecture.  Bootstrap
   images will be built 'by hand' on target hosts until such a time when the
   CI is capable of executing the docker image builder scripts inside docker
   images running on Nomad instances via jenkins jobs.

2. For each OS package manager, there is a bash function which generates the
   Dockerfile for the specified OS which uses said package manager. For example,
   lib_apt.sh contains 'generate_apt_dockerfile()' which is executed for Ubuntu
   and debian OS's.  lib_yum.sh and lib_dnf.sh contain similar functions for yum
   (centos-7) and dnf (centos-8).

3. The Dockerfiles contain the following sections:
 - a. Environment setup and copying of project workspace git repos
 - b. Installation of OS package pre-requisites
 - c. Docker install and project requirements installation (more on this below)
 - d. Working environment setup
 - e. Build cleanup

4. The Project installation section (c.) above is where all of the packages
   for each of the supported project branches are installed or cached to
   save time and bandwidth when the CI jobs are run.  Each project script
   defines the branches supported for each OS and iterates over them from
   oldest to newest using the dependency and requirements files or build
   targets in each supported project branch.

5. `docker build` is run on the generated Dockerfile.

## Bash Libraries (lib_*.sh)

The bash libraries are designed to be sourced both inside of the docker build
environment (e.g. from a script invoked in a Dockerfile RUN statement) as well
as in a normal Linux shell. These scripts create environment variables and
bash functions for use by the operational scripts.

- `lib_apt.sh`: Dockerfile generation functions for apt package manager.

- `lib_common.sh`: Common utility functions and environment variables

- `lib_csit.sh`: CSIT specific functions and environment variables

- `lib_dnf.sh`: Dockerfile generation functions for dnf package manager.

- `lib_vpp.sh`: VPP specific functions and environment variables

- `lib_yum.sh`: Dockerfile generation functions for yum package manager.

## Bash Scripts

There are two types of bash scripts, those intended to be run solely inside
the docker build execution environment, the other run either inside or
outside of it.

### Docker Build (dbld_*.sh) Scripts

These scripts run inside the 'docker build' environment are either per-project
scripts that install OS and python packages or scripts that install other docker
image runtime requirements.

Python packages are not retained because they are typically installed in virtual
environments. However installing the python packages in the Docker Build scripts
populates the pip/http caches. Therefore packages are installed from the cache
files during CI job execution instead of being downloaded from the Internet.

- `dbld_csit_find_ansible_packages.sh`: Script to find OS packages installed by
CSIT using ansible.

- `dbld_csit_install_packages.sh`: Install OS and python packages for CSIT
branches

- `dbld_dump_build_logs.sh`: Find warnings/errors in the build logs and dump
the build_executor_docker_image.sh execution log.

- `dbld_install_docker.sh`: Install docker ce

- `dbld_lfit_requirements.sh`: Install requirements for LFIT global-jjb
macros / scripts

- `dbld_vpp_install_packages.sh`: Install OS and python packages for VPP
branches

### Executor Docker Image Management Bash Scripts

These scripts are used to build executor docker images, inspect the results, and
manage the docker image tags in the Docker Hub fdiotools repositories.

- `build_executor_docker_image.sh`: Build script to create one or more executor
docker images.

- `update_dockerhub_prod_tags.sh`: Inspect/promote/revert production docker tag
in the Docker Hub fdiotools repositories.

## Running The Scripts

### Bootstrapping The Builder Images

The following commands are useful to build the initial builder images:

`cd <ci-managment repository directory>`

`sudo ./docker/scripts/build_executor_docker_image.sh ubuntu-18.04 2>&1 | tee u1804-$(uname -m).log | grep -ve '^+'`

`sudo ./docker/scripts/build_executor_docker_image.sh centos-7 2>&1 | tee centos7-$(uname -m).log | grep -ve '^+'`

`sudo ./docker/scripts/build_executor_docker_image.sh -apr sandbox 2>&1 | tee all-sandbox-$(uname -m).log | grep -ve '^+'`

### Building in a Builder Image

By running the docker image with docker socket mounted in the container,
the docker build environment runs on the host's docker daemon.  This
avoids the pitfalls encountered with Docker-In-Docker environments:

`sudo docker run -it -v /var/run/docker.sock:/var/run/docker.sock <docker-image>`

The environment in the docker shell contains all of the necessary
environment variable definitions so the docker scripts can be run
directly on the cli.  Here is an example command that would be used in a CI job
which automates the generation and testing of a new ubuntu-18.04 docker image
and push it to Docker Hub fdiotools/builder-ubuntu1804:test-<arch>:

`build_executor_docker_image.sh -pr test ubuntu-18.04`

In the future, a fully automated CI/CD pipeline may be created for production
docker images.

# Docker Image Script Workflow

This section describes the current workflow used for managing the CI/CD pipeline
for the Docker Images used by the FD.io CI Jobs.

Note: all operations that push images or image tags to Docker Hub require an
account with management privileges of the fdiotools repositories.

## Update Production Docker Images

Note: Presently only the 'builder' class executor docker images are supported.
The others will be supported in the near future.

### Build Docker Images and Push to Docker Hub with Sandbox CI Tag

For each hardware architecture, the build_executor_docker_image.sh script is
used to build all variants of the each executor class:

1. `git clone https://gerrit.fd.io/r/ci-management && cd ci-management`

2. `sudo ./docker/scripts/build_executor_docker_image.sh -p -r sandbox -a | tee builder-all-sandbox-$(uname -m).log | grep -ve '^+'``

3. `Inspect the build log for Errors and other build anomalies`

This step will take a very long time so best to do it overnight. There is not
currently an option to automatically run builds in parallel, so if optimizing
build times is important, then run the jobs in separate shells for each OS.
The aarch64 builds are particularly slow, thus may benefit from being run on
separate hosts in parallel.

Note: the 'prod' role is disallowed in the build script to prevent accidental
deployment of untested docker images to production.

### Test Docker Images in the Jenkins Sandbox

In the future, this step will be automated using the role 'test' and associated
tags, but for now testing is a manual operation.

1. `git clone https://gerrit.fd.io/r/vpp ../vpp && source ../vpp/extras/bash/functions.sh`

2. Edit jjb/vpp/vpp.yam (or other project yaml file) and replace '-prod-' with '-sandbox-' for all of the docker image

3. `jjb-sandbox-env`  # This bash function currently lives in ../vpp/extras/bash/functions.sh  
 - TODO: move it to ci-management repo.

4. For each job using one of the docker images:

   a. `jjsb-update <job name(s)>` # bash function created by jjb-sandbox-env to
   push job to the sandbox

   b. manually run the job in https://jenkins.fd.io/sandbox

   c. Inspect the console output of each job for unnecessary downloads & errors.

### Promote Docker Images to Production

Once all of the docker images have been tested, promote each one to production:

`sudo ./docker/scripts/update_dockerhub_prod_tags.sh promote <image name>`

Note: this script currently requires human acceptance via the terminal to ensure
correctness.
It pulls all tags from the Docker Hub repos, does an Inspect action (displaying
the current state of 'prod' & 'prod-prev' tags) and local Promotion action (i.e.
tags local images with 'prod-<arch>' and 'prod-prev-<arch>') with a required
confirmation to continue the promotion by pushing the tags to Docker Hub. If
'no' is specified, it restores the previous local tags so they match the state
of Docker Hub and does a new Inspect action for verification.  If 'yes' is
specified, it prints out the command to use to restore the existing state of the
production tags on Docker Hub in case the script is terminated prior to
completion.  If necessary, the restore command can be repeated multiple times
until it completes successfully since it promotes the 'prod-prev-<arch>' image,
then the 'prod-<arch>' image in succession.

## Other Docker Hub Operations

### Inspect Production Docker Image Tags

Inspect the current production docker image tags:

`sudo ./docker/scripts/update_dockerhub_prod_tags.sh inspect fdiotools/<class>-<os name>:prod-$(uname -m)`

### Revert Production Docker Image To Previous Docker Image

Inspect the current production docker image tags:

`sudo ./docker/scripts/update_dockerhub_prod_tags.sh revert fdiotools/<class>-<os name>:prod-$(uname -m)`

### Restoring Previous Production Image State

Assuming that the images still exist in the Docker Hub repository, any previous
state of the production image tags can be restored by executing the 'restore
command' as output by the build_executor_docker_image.sh script.  This script
writes a copy of all of the terminal output to a log file in
/tmp/build_executor_docker_image.sh.<date>.log thus providing a history of the
restore commands. When the building of executor docker images is peformed by a
CI job, the logging can be removed since the job execution will be captured in
the Jenkins console output log.

### Docker Image Garbage Collection

Presently, cleaning up the Docker Hub repositories of old images/tags is a
manual process using the Docker Hub WebUI.  In the future, a garbage collection
script will be written to automate the process.

# DockerHub Repository & Docker Image Tag Nomenclature:

## DockerHub Repositories

- fdiotools/builder-centos7
- fdiotools/builder-centos8
- fdiotools/builder-debian9
- fdiotools/builder-debian10
- fdiotools/builder-ubuntu1804
- fdiotools/builder-ubuntu2004
- fdiotools/csit-ubuntu1804
- fdiotools/csit_dut-ubuntu1804
- fdiotools/csit_shim-ubuntu1804

## Docker Image Tags

- prod-x86_64: Tag used to select the x86_64 production image by the associated
Jenkins-Nomad Label.
- prod-prev-x86_64: Tag of the previous x86_64 production image used to revert
a production image to the previous image used in production.
- prod-aarch64: Tag used to select the aarch64 production image by the
associated Jenkins-Nomad Label.
- prod-prev-aarch64 Tag of the previous aarch64 production image used to revert
a production image to the previous image used in production.
- sandbox-x86_64: Tag used to select the x86_64 sandbox image by the associated
Jenkins-Nomad Label.
- sandbox-aarch64: Tag used to select the aarch64 sandbox image by the
associated Jenkins-Nomad Label.
- test-x86_64: Tag used to select the x86_64 sandbox image by the associated
Jenkins-Nomad Label.
- test-aarch64: Tag used to select the aarch64 sandbox image by the associated
Jenkins-Nomad Label.

# Jenkins-Nomad Label Definitions

<class>-<os>-<role>-<arch>  (e.g. builder-ubuntu1804-prod-x86_64)

- class
-- builder
-- csit
-- csit_dut
-- csit_shim

- os
-- ubuntu1804
-- centos7
-- ubuntu2004
-- centos8
-- debian9
-- debian10

- role
-- prod
-- test
-- sandbox

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

#### Node 'builder-ubuntu1804-prod-x86_64'
- Labels: builder-ubuntu1804-prod-x86_64
- Job Prefix: builder-ubuntu1804-prod-x86_64
- Image: fdiotools/builder-ubuntu1804:prod-x86_64
- CPU: 14000
- Memory: 14000
- ${attr.cpu.arch}: amd64
- ${node.class}: builder

#### Node 'builder-ubuntu1804-prod-aarch64'
- Labels: builder-ubuntu1804-prod-aarch64
- Job Prefix: builder-ubuntu1804-prod-aarch64
- Image: fdiotools/builder-ubuntu1804:prod-aarch64
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

#### Node 'builder-ubuntu2004-prod-x86_64'
- Labels: builder-ubuntu2004-prod-x86_64
- Job Prefix: builder-ubuntu2004-prod-x86_64
- Image: fdiotools/builder-ubuntu2004:prod-x86_64
- CPU: 14000
- Memory: 14000
- ${attr.cpu.arch}: amd64
- ${node.class}: builder

#### Node 'builder-ubuntu2004-prod-aarch64'
- Labels: builder-ubuntu2004-prod-aarch64
- Job Prefix: builder-ubuntu2004-prod-aarch64
- Image: fdiotools/builder-ubuntu2004:prod-aarch64
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

#### Node 'csit_dut-ubuntu1804-prod-x86_64'
- Labels: csit_dut-ubuntu1804-prod-x86_64
- Job Prefix: csit_dut-ubuntu1804-prod-x86_64
- Image: fdiotools/csit_dut-ubuntu1804:prod-x86_64
- CPU: 10000
- Memory: 18000
- ${attr.cpu.arch}: amd64
- ${node.class}: csit

#### Node 'csit_dut-ubuntu1804-prod-aarch64'
- Labels: csit_dut-ubuntu1804-prod-aarch64
- Job Prefix: csit_dut-ubuntu1804-prod-aarch64
- Image: fdiotools/csit_dut-ubuntu1804:prod-aarch64
- CPU: 6000
- Memory: 10000
- ${attr.cpu.arch}: arm64
- ${node.class}: csitarm

#### Node 'csit_shim-ubuntu1804-prod-x86_64'
- Labels: csit_shim-ubuntu1804-prod-x86_64
- Job Prefix: csit_shim-ubuntu1804-prod-x86_64
- Image: fdiotools/csit_shim-ubuntu1804:prod-x86_64
- CPU: 10000
- Memory: 18000
- ${attr.cpu.arch}: amd64
- ${node.class}: csit

#### Node 'csit_shim-ubuntu1804-prod-aarch64'
- Labels: csit_shim-ubuntu1804-prod-aarch64
- Job Prefix: csit_shim-ubuntu1804-prod-aarch64
- Image: fdiotools/csit_shim-ubuntu1804:prod-aarch64
- CPU: 6000
- Memory: 10000
- ${attr.cpu.arch}: arm64
- ${node.class}: csitarm

### Sandbox (sandbox) Jenkins Nomad Plugin Nodes

#### Node 'builder-ubuntu1804-sandbox-x86_64'
- Labels: builder-ubuntu1804-sandbox-x86_64
- Job Prefix: builder-ubuntu1804-sandbox-x86_64
- Image: fdiotools/builder-ubuntu1804:sandbox-x86_64
- CPU: 14000
- Memory: 14000
- ${attr.cpu.arch}: amd64
- ${node.class}: builder

#### Node 'builder-ubuntu1804-sandbox-aarch64'
- Labels: builder-ubuntu1804-sandbox-aarch64
- Job Prefix: builder-ubuntu1804-sandbox-aarch64
- Image: fdiotools/builder-ubuntu1804:sandbox-aarch64
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

#### Node 'builder-ubuntu2004-sandbox-x86_64'
- Labels: builder-ubuntu2004-sandbox-x86_64
- Job Prefix: builder-ubuntu2004-sandbox-x86_64
- Image: fdiotools/builder-ubuntu2004:sandbox-x86_64
- CPU: 14000
- Memory: 14000
- ${attr.cpu.arch}: amd64
- ${node.class}: builder

#### Node 'builder-ubuntu2004-sandbox-aarch64'
- Labels: builder-ubuntu2004-sandbox-aarch64
- Job Prefix: builder-ubuntu2004-sandbox-aarch64
- Image: fdiotools/builder-ubuntu2004:sandbox-aarch64
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

#### Node 'csit_dut-ubuntu1804-sandbox-x86_64'
- Labels: csit_dut-ubuntu1804-sandbox-x86_64
- Job Prefix: csit_dut-ubuntu1804-sandbox-x86_64
- Image: fdiotools/csit_dut-ubuntu1804:sandbox-x86_64
- CPU: 10000
- Memory: 18000
- ${attr.cpu.arch}: amd64
- ${node.class}: csit

#### Node 'csit_dut-ubuntu1804-sandbox-aarch64'
- Labels: csit_dut-ubuntu1804-sandbox-aarch64
- Job Prefix: csit_dut-ubuntu1804-sandbox-aarch64
- Image: fdiotools/csit_dut-ubuntu1804:sandbox-aarch64
- CPU: 6000
- Memory: 10000
- ${attr.cpu.arch}: arm64
- ${node.class}: csitarm

#### Node 'csit_shim-ubuntu1804-sandbox-x86_64'
- Labels: csit_shim-ubuntu1804-sandbox-x86_64
- Job Prefix: csit_shim-ubuntu1804-sandbox-x86_64
- Image: fdiotools/csit_shim-ubuntu1804:sandbox-x86_64
- CPU: 10000
- Memory: 18000
- ${attr.cpu.arch}: amd64
- ${node.class}: csit

#### Node 'csit_shim-ubuntu1804-sandbox-aarch64'
- Labels: csit_shim-ubuntu1804-sandbox-aarch64
- Job Prefix: csit_shim-ubuntu1804-sandbox-aarch64
- Image: fdiotools/csit_shim-ubuntu1804:sandbox-aarch64
- CPU: 6000
- Memory: 10000
- ${attr.cpu.arch}: arm64
- ${node.class}: csitarm

### Automated Testing (test) Jenkins Nomad Plugin Nodes

#### Node 'builder-ubuntu1804-test-x86_64'
- Labels: builder-ubuntu1804-test-x86_64
- Job Prefix: builder-ubuntu1804-test-x86_64
- Image: fdiotools/builder-ubuntu1804:test-x86_64
- CPU: 14000
- Memory: 14000
- ${attr.cpu.arch}: amd64
- ${node.class}: builder

#### Node 'builder-ubuntu1804-test-aarch64'
- Labels: builder-ubuntu1804-test-aarch64
- Job Prefix: builder-ubuntu1804-test-aarch64
- Image: fdiotools/builder-ubuntu1804:test-aarch64
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

#### Node 'builder-ubuntu2004-test-x86_64'
- Labels: builder-ubuntu2004-test-x86_64
- Job Prefix: builder-ubuntu2004-test-x86_64
- Image: fdiotools/builder-ubuntu2004:test-x86_64
- CPU: 14000
- Memory: 14000
- ${attr.cpu.arch}: amd64
- ${node.class}: builder

#### Node 'builder-ubuntu2004-test-aarch64'
- Labels: builder-ubuntu2004-test-aarch64
- Job Prefix: builder-ubuntu2004-test-aarch64
- Image: fdiotools/builder-ubuntu2004:test-aarch64
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

#### Node 'csit_dut-ubuntu1804-sandbox-x86_64'
- Labels: csit_dut-ubuntu1804-sandbox-x86_64
- Job Prefix: csit_dut-ubuntu1804-sandbox-x86_64
- Image: fdiotools/csit_dut-ubuntu1804:sandbox-x86_64
- CPU: 10000
- Memory: 18000
- ${attr.cpu.arch}: amd64
- ${node.class}: csit

#### Node 'csit_dut-ubuntu1804-test-aarch64'
- Labels: csit_dut-ubuntu1804-test-aarch64
- Job Prefix: csit_dut-ubuntu1804-test-aarch64
- Image: fdiotools/csit_dut-ubuntu1804:test-aarch64
- CPU: 6000
- Memory: 10000
- ${attr.cpu.arch}: arm64
- ${node.class}: csitarm

#### Node 'csit_shim-ubuntu1804-test-aarch64'
- Labels: csit_shim-ubuntu1804-test-aarch64
- Job Prefix: csit_shim-ubuntu1804-test-aarch64
- Image: fdiotools/csit_shim-ubuntu1804:test-aarch64
- CPU: 6000
- Memory: 10000
- ${attr.cpu.arch}: arm64
- ${node.class}: csitarm
