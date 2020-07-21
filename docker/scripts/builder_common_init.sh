#! /bin/bash

set -euxo pipefail

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. $CIMAN_DOCKER_SCRIPTS/lib_common.sh

# Add jenkins user
groupadd jenkins || true
useradd -m -s /bin/bash -g jenkins jenkins

# Check if docker group exists
set +e
grep -q docker /etc/group
retval="$?"
set -e
if [ "$retval" == '0' ]
then
  # Add jenkins user to docker group
  usermod -a -G docker jenkins
fi

# Check if mock group exists
set +e
grep -q mock /etc/group
retval="$?"
set -e
if [ "$retval" == '0' ]
then
  # Add jenkins user to mock group so it can build RPMs using mock if available
  usermod -a -G mock jenkins
fi

# Give jenkins account root privileges
jenkins_uid=$(id -u jenkins)
perl -i -p -e "s/$jenkins_uid\:/0\:/g" /etc/passwd

# Copy lf-env.sh for LF Releng scripts
cp $DOCKER_CIMAN_ROOT/global-jjb/jenkins-init-scripts/lf-env.sh /root
chmod 644 /root/lf-env.sh

# Install lftools[openstack] -- from global-jjb/shell/python-tools-install.sh
python3 -m pip install lftools[openstack]
