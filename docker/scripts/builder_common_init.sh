#! /bin/bash

set -euxo pipefail

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
