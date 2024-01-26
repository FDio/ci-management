# CI (Continuous Integration Management) Folder Structure

1. <b>Docker Folder</b> - It contains collection of bash scripts and libraries is used to automate the process of building FD.io docker 'builder' images (aka Nomad executors).

<br>

1. <b>JJB Folder</b> - Jekins is the CI head which runs the specific gerrit patch and shows you the latest changes. This folders contains all the yaml files which specifies which jobs need to run during the deployement of the latest changes. For example - [lf-python-job-groups.yaml](https://github.com/lfit/releng-global-jjb/blob/d31ff4635d1dc4a6afe4cf3be622a219be5f1318/jjb/lf-python-job-groups.yaml) specifics remoomended jobs to run when a new python project needs to be tested, build or deploy based on the requirements.

<br>

3. <b>Global JJB Folder</b> - This folder is just a library project which contains reusable Jenkins Job Builder templates developed by the Linux Foundation CI [LFCI].

<br>

4. <b>Nodepool Folder</b> - Nodepool is a system used in the context of OpenStack and Jenkins to manage the dynamic provisioning of virtual machines (VMs) or containers for use as build and test nodes. Nodepool is often used in conjunction with Jenkins, and can leverage Nodepool to spawn and manage worker nodes for running builds, tests, and other tasks.

<br>

5. <b>Packer Folder</b> - Packer is a tool for automatically creating VM and container images, configuring them and post-processing them into standard output formats. All the FD.io's CI images are build via Packer.

<br>

6. <b>Zuul Folder</b> - This provides a configuration that defines various CI/CD pipelines, a project template with default jobs, and specific projects with associated check and post-merge jobs. The pipelines are triggered by events such as code submissions, comments, or periodic timers, and they interact with the Gerrit code review system by providing feedback on the success or failure of the jobs .
