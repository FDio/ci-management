#! /bin/bash

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

set -euxo pipefail

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. $CIMAN_DOCKER_SCRIPTS/lib_common.sh

must_be_run_as_root
must_be_run_in_docker_build

# Add jenkins user and make it equivalent to root
groupadd jenkins || true
useradd -m -s /bin/bash -g jenkins jenkins || true
rm -rf /home/jenkins
ln -s /root /home/jenkins

# Add packagecloud files
cat <<EOF > /root/.packagecloud
{"url":"https://packagecloud.io","token":"\$token"}
EOF
cat <<EOF >/root/packagecloud_api
machine packagecloud.io
login \$pclogin
password
EOF

# Check if docker group exists
if grep -q docker /etc/group
then
    # Add jenkins user to docker group
    usermod -a -G docker jenkins
fi

# Check if mock group exists
if grep -q mock /etc/group
then
    # Add jenkins user to mock group so it can build RPMs
    # using mock if available
    usermod -a -G mock jenkins
fi

# Give jenkins account root privileges
jenkins_uid=$(id -u jenkins)
perl -i -p -e "s/$jenkins_uid\:/0\:/g" /etc/passwd

# Copy lf-env.sh for LF Releng scripts
lf_env_sh="/root/lf-env.sh"
cp $CIMAN_DOCKER_SCRIPTS/fdio-lf-env.sh $lf_env_sh

# Install lftools & boto3 for log / artifact upload.
python3 -m pip install boto3
source $lf_env_sh
lf-activate-venv lftools
deactivate
