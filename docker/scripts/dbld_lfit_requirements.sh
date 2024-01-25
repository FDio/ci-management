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
. "$CIMAN_DOCKER_SCRIPTS/lib_common.sh"

must_be_run_in_docker_build

# Add packagecloud files
cat <<EOF >/root/.packagecloud
{"url":"https://packagecloud.io","token":"\$token"}
EOF
cat <<EOF >/root/packagecloud_api
machine packagecloud.io
login \$pclogin
password
EOF

# Copy lf-env.sh for LF Releng scripts
lf_env_sh="/root/lf-env.sh"
cp "$DOCKER_CIMAN_ROOT/global-jjb/jenkins-init-scripts/lf-env.sh" "$lf_env_sh"
chmod 644 "$lf_env_sh"
cat <<EOF >>"$lf_env_sh"

# When running in CI docker image, use the pre-installed venv
# instead of installing python packages every job run.
#
unset -f lf-activate-venv
lf-activate-venv() {
    echo "\${FUNCNAME[0]}(): INFO: Adding $LF_VENV/bin to PATH"
    PATH="\$LF_VENV/bin:\$PATH"
    return 0
}
EOF

# Install lftools & boto3 for log / artifact upload.
python3 -m pip install boto3
mkdir -p "$LF_VENV"
OLD_PATH="$PATH"
python3 -m venv "$LF_VENV"
PATH="$LF_VENV/bin:$PATH"
python3 -m pip install --upgrade --upgrade-strategy eager lftools
PATH="$OLD_PATH"
