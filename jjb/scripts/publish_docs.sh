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

if [[ "${SILO}" != "production" ]] ; then
    echo "WARNING: Doc upload not supported on Jenkins '${SILO}'..."
    exit 0
fi

CDN_URL="s3-docs.fd.io"

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
        *"vpp-docs"*)
            vpp_release="$(${WORKSPACE}/build-root/scripts/version rpm-version)"
            # TODO: Remove conditional statement when stable/2106 and
            #       stable/2110 are no longer supported
            if [[ "${vpp_release::2}" -ge "22" ]] ; then
                workspace_dir="${WORKSPACE}/build-root/docs/html"
            else
                workspace_dir="${WORKSPACE}/docs/_build/html"
            fi
            bucket_path="/vpp/${vpp_release}/"
            ;;
        # TODO: Remove 'vpp-make-test-docs' when stable/2106 and
        #       stable/2110 are no longer supported
        *"vpp-make-test-docs"*)
            vpp_release="$(${WORKSPACE}/build-root/scripts/version rpm-version)"
            workspace_dir="${WORKSPACE}/test/doc/build/html"
            bucket_path="/vpp/${vpp_release}/vpp_make_test/html/"
            ;;
        *)
            die "Unknown job: ${JOB_NAME}"
    esac

    export TF_VAR_workspace_dir=$workspace_dir
    export TF_VAR_bucket_path=$bucket_path
    export AWS_SHARED_CREDENTIALS_FILE=$HOME/.aws/credentials
    export AWS_DEFAULT_REGION="us-east-1"

    echo "INFO: archiving docs to S3"
    pushd ..
    terraform init -no-color
    terraform apply -no-color -auto-approve
    popd

    echo "S3 docs: <a href=\"https://${CDN_URL}${bucket_path}\">https://${CDN_URL}${bucket_path}</a>"
fi
