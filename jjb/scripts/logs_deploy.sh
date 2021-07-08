#!/bin/bash

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

echo "---> logs-deploy.sh"

# shellcheck disable=SC1090
source ~/lf-env.sh
lf-activate-venv lftools

CDN_URL="logs.nginx.service.consul"

# FIXME: s3 config (until migrated to config provider, then pwd will be reset)
mkdir -p ${HOME}/.aws
echo "[fdio-logs-s3-nomad]" >> "$HOME/.aws/config"
echo "[fdio-logs-s3-nomad]
aws_access_key_id = storage
aws_secret_access_key = Storage1234" >> "$HOME/.aws/credentials"

# The 'lftool deploy archives' command below expects the archives
# directory to exist.  Normally lf-infra-sysstat or similar would
# create it and add content, but to make sure this script is
# self-contained, we ensure it exists here.
mkdir -p "$WORKSPACE/archives"

get_pattern_opts () {
    opts=()
    for arg in ${ARCHIVE_ARTIFACTS:-}; do
        opts+=("-p" "$arg")
    done
    echo "${opts[@]-}"
}

pattern_opts=$(get_pattern_opts)

s3_path="$JENKINS_HOSTNAME/$JOB_NAME/$BUILD_NUMBER/"
echo "INFO: S3 path $s3_path"

echo "INFO: archiving logs to S3"
# shellcheck disable=SC2086
#lftools deploy s3 ${pattern_opts:-} "logs.fd.io" "$s3_path" \
#    "$BUILD_URL" "$WORKSPACE"

echo "S3 build logs: <a href=\"https://$CDN_URL/$s3_path\">https://$CDN_URL/$s3_path</a>"
