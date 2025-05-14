#!/bin/bash

# Copyright (c) 2023 Cisco and/or its affiliates.
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

echo "---> publish_cov.sh"

set -exuo pipefail

CDN_URL="s3-docs-7day.fd.io"
bucket="vpp-docs-7day-retention"
# Use the same bucket path as logs so that the code coverage report can be viewed by
# s/s3-logs/s3-docs-7day/ in the URL after selecting the logs URL from
# the jenkins job page.
bucket_path="$JENKINS_HOSTNAME/$JOB_NAME/$BUILD_NUMBER/"

if [[ ${JOB_NAME} == *verify* ]]; then
    case "${JOB_NAME}" in
        *"vpp-cov"*)
            workspace_dir="${WORKSPACE}/build-root/test-coverage/html"
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

echo "INFO: archiving test coverage to S3 bucket '$bucket'"
pushd ..
terraform init -no-color
terraform apply -no-color -auto-approve
popd

echo "S3 Test Coverage: <a href=\"https://${CDN_URL}/${bucket_path}\">https://${CDN_URL}/${bucket_path}</a>"

# Check result
FAILED_TESTS=""
FAILED_HSTESTS=""

FAILURE_REGEX='--- addFailure\(\) ([A-Za-z0-9-]+\.[a-zA-Z0-9_-]+)'
for dir in /tmp/vpp-failed-unittests/*; do
    TESTCLASS_LOG="$(gunzip -c $dir/log.txt.gz)"
    while [[ $TESTCLASS_LOG =~ $FAILURE_REGEX ]]; do
        FAILED_TESTS="$FAILED_TESTS${BASH_REMATCH[1]}"$'\n'
	TESTCLASS_LOG=${TESTCLASS_LOG/"${BASH_REMATCH[0]}"/}
    done
done
if [[ -n $FAILED_TESTS ]]; then
    echo -e "make test coverage run failed!\nFailed tests:\n$FAILED_TESTS"
else
    echo "make test coverage run succeeded!"
fi
if [[ -f extras/hs-test/summary/report.json ]]; then
    FAILED_HSTESTS=$(jq '.[].SpecReports[] | select(.State=="failed").LeafNodeText' extras/hs-test/summary/report.json)
    if [[ -n $FAILED_HSTESTS ]]; then
	echo -e "hs-test coverage run failed!\nFailed tests:\n$FAILED_HSTESTS"
    else
        echo "hs-test coverage run succeeded!"
    fi
else
    echo "hs-test framework failed!"
fi

if [[ -n $FAILED_TESTS || -n $FAILED_HSTESTS ]]; then
   die "Some tests failed, check the log!"
fi

