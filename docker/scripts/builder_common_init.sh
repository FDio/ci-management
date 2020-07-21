#! /bin/bash

# Copyright (c) 2020 Cisco and/or its affiliates.
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

set -euxo pipefail

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. $CIMAN_DOCKER_SCRIPTS/lib_common.sh

# Add jenkins user
groupadd jenkins || true
useradd -m -s /bin/bash -g jenkins jenkins
rm -rf /home/jenkins
ln -s /root /home/jenkins

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
pinned_version=""
if [ "$OS_NAME" = "debian-9" } ; then
  # debian-9 does not have osc-lib==2.2.0 available breaking docker image build
  # so pin the version of lftools which does not pin osc-lib==2.2.0
  pinned_version="==0.34.1"
fi
python3 -m pip install --no-deps lftools[openstack]$pinned_version
