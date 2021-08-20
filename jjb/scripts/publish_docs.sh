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

echo "---> publish_docs.sh"

set -exuo pipefail

S3_BUCKET="fdio-docs-s3-cloudfront-index"
CDN_URL="s3-docs.fd.io"
PYTHON_SCRIPT="/w/workspace/publish_library.py"

if [[ ${JOB_NAME} == *merge* ]]; then
    case "${JOB_NAME}" in
        *"csit-trending"*)
            SITE_DIR="${WORKSPACE}/resources/tools/presentation/_build"
            s3_path="csit/${GERRIT_BRANCH}/trending"
            ;;
        *"csit-report"*)
            SITE_DIR="${WORKSPACE}/resources/tools/presentation/_build"
            s3_path="csit/${GERRIT_BRANCH}/report"
            ;;
        *"csit-docs"*)
            SITE_DIR="${WORKSPACE}/resources/tools/doc_gen/_build"
            s3_path="csit/${GERRIT_BRANCH}/docs"
            ;;
        *)
            die "Unknown job: ${JOB_NAME}"
    esac

    echo "INFO: S3 path $s3_path"

    echo "INFO: archiving docs to S3"
    python3 $PYTHON_SCRIPT deploy_docs "$S3_BUCKET" "$s3_path" "$SITE_DIR"

    echo "S3 docs: <a href=\"https://$CDN_URL/$s3_path\">https://$CDN_URL/$s3_path</a>"
fi
