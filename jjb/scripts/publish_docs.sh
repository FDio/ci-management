#!/bin/bash

# Copyright (c) 2022 Cisco and/or its affiliates.
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

CDN_URL="s3-docs.fd.io"
bucket="fdio-docs-s3-cloudfront-index"

if [[ ${JOB_NAME} == *merge* ]]; then
    case "${JOB_NAME}" in
        *"csit-trending"*)
            workspace_dir="${WORKSPACE}/resources/tools/presentation/_build"
            bucket_path="/csit/${GERRIT_BRANCH}/trending/"
            ;;
        *"csit-report"*)
            workspace_dir="${WORKSPACE}/resources/tools/presentation/_build"
            bucket_path="/csit/${GERRIT_BRANCH}/report/"
            ;;
        *"csit-docs"*)
            workspace_dir="${WORKSPACE}/resources/tools/doc_gen/_build"
            bucket_path="/csit/${GERRIT_BRANCH}/docs/"
            ;;
        *"hicn-docs"*)
            hicn_release="$(git describe --long --match "v*" | cut -d- -f1 | sed -e 's/^v//')"
            workspace_dir="${WORKSPACE}/build/doc/deploy-site"
            bucket_path="/hicn/${hicn_release}/"
            ;;
        *"vpp-docs"*)
            vpp_release="$(${WORKSPACE}/build-root/scripts/version rpm-version)"
            workspace_dir="${WORKSPACE}/build-root/docs/html"
            bucket_path="/vpp/${vpp_release}/"
            ;;
        *)
            die "Unknown job: ${JOB_NAME}"
    esac
elif [[ ${JOB_NAME} == *verify* ]]; then
    bucket="vpp-docs-7day-retention"
    # Use the same bucket path as logs so that the docs can be viewed by
    # s/s3-logs/s3-docs-7day/ in the URL after selecting the logs URL from
    # the jenkins job page.
    bucket_path="$JENKINS_HOSTNAME/$JOB_NAME/$BUILD_NUMBER/"
    case "${JOB_NAME}" in
        *"hicn-docs"*)
            workspace_dir="${WORKSPACE}/build/doc/deploy-site"
            ;;
        *"vpp-docs"*)
            CDN_URL="s3-docs-7day.fd.io"
            workspace_dir="${WORKSPACE}/build-root/docs/html"
            ;;
        *)
            die "Unknown job: ${JOB_NAME}"
    esac
else
    die "Unknown job: ${JOB_NAME}"
fi

export TF_VAR_workspace_dir="$workspace_dir"
export TF_VAR_bucket_path="$bucket_path"
export TF_VAR_bucket="$bucket"
export AWS_SHARED_CREDENTIALS_FILE=$HOME/.aws/credentials
export AWS_DEFAULT_REGION="us-east-1"

echo "INFO: archiving docs to S3 bucket '$bucket'"
pushd ..
terraform init -no-color
terraform apply -no-color -auto-approve
popd

echo "S3 docs: <a href=\"https://${CDN_URL}/${bucket_path}\">https://${CDN_URL}/${bucket_path}</a>"
