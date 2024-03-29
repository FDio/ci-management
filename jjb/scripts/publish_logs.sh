#!/bin/bash

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

echo "---> publish_logs.sh"

PYTHON_SCRIPT="/w/workspace/publish_library.py"

mkdir -p "$WORKSPACE/archives"

s3_path="$JENKINS_HOSTNAME/$JOB_NAME/$BUILD_NUMBER/"

echo "INFO: S3 path $s3_path"

echo "INFO: archiving logs to S3"
python3 $PYTHON_SCRIPT deploy_s3 "$S3_BUCKET" "$s3_path" \
    "$BUILD_URL" "$WORKSPACE"

echo "S3 build logs: <a href=\"https://$CDN_URL/$s3_path\">https://$CDN_URL/$s3_path</a>"
