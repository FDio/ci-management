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

# Add packagecloud files
cat <<EOF > /root/.packagecloud
{"url":"https://packagecloud.io","token":"\$token"}
EOF
cat <<EOF >/root/packagecloud_api
machine packagecloud.io
login \$pclogin
password
EOF

# Copy lf-env.sh for LF Releng scripts
lf_env_sh="/root/lf-env.sh"
cp $CIMAN_DOCKER_SCRIPTS/fdio-lf-env.sh $lf_env_sh

# Install lftools & boto3 for log / artifact upload.
python3 -m pip install boto3
mkdir -p $LF_VENV
source $lf_env_sh
# Note: Don't add $LF_VENV/bin to path in case there are every any scripts
#       run after this one.  Otherwise pip3 will install them into this venv.
lf-activate-venv --no-path lftools
