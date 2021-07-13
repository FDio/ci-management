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

echo "---> publish_site.sh"

set -exuo pipefail

PYTHON_SCRIPT="/w/workspace/test-logs/publish_docs.py"

# This script uploads the site artifacts to a upload location.
if [ -f "$PYTHON_SCRIPT" ]; then
    echo "WARNING: $PYTHON_SCRIPT already exists"
    exit 0
fi

pip3 install boto3
mkdir -p $(dirname "$PYTHON_SCRIPT")

cat >$PYTHON_SCRIPT <<'END_OF_PYTHON_SCRIPT'
#!/usr/bin/python3

"""Storage utilities library."""

import logging
import os
import sys
from mimetypes import MimeTypes

import boto3
from botocore.exceptions import ClientError


logging.basicConfig(
    format=u"%(levelname)s: %(message)s",
    stream=sys.stdout,
    level=logging.INFO
)
logging.getLogger(u"botocore").setLevel(logging.INFO)


def upload(s3_resource, s3_bucket, src_fpath, s3_path):
    """Upload single file to destination bucket.

    :param s3_resource: S3 storage resource.
    :param s3_bucket: S3 bucket name.
    :param src_fpath: Input file path.
    :param s3_path: Destination file path on remote storage.
    :type s3_resource: Object
    :type s3_bucket: str
    :type src_fpath: str
    :type s3_path: str
    """
    mime_guess = MimeTypes().guess_type(src_fpath)
    mime = mime_guess[0]
    encoding = mime_guess[1]
    if not mime:
        mime = u"application/octet-stream"

    extra_args = {u"ContentType": mime}

    try:
        logging.info(u"Attempting to upload file " + src_fpath)
        s3_resource.Bucket(s3_bucket).upload_file(
            src_fpath, s3_path, ExtraArgs=extra_args
        )
        logging.info(u"Successfully uploaded to " + s3_path)
    except ClientError as e:
        logging.error(e)


def upload_recursive(s3_resource, s3_bucket, src_fpath, s3_path):
    """Recursively uploads input folder to destination.

    Example:
      - s3_bucket: logs.fd.io
      - src_fpath: /workspace/archives.
      - s3_path: /hostname/job/id/

    :param s3_resource: S3 storage resource.
    :param s3_bucket: S3 bucket name.
    :param src_fpath: Input folder path.
    :param s3_path: S3 destination path.
    :type s3_resource: Object
    :type s3_bucket: str
    :type src_fpath: str
    :type s3_path: str
    """
    for path, _, files in os.walk(src_fpath):
        for file in files:
            _path = path.replace(src_fpath, u"")
            _src_fpath = path + u"/" + file
            _s3_path = os.path.normpath(s3_path + u"/" + _path + u"/" + file)
            upload(
                s3_resource=s3_resource,
                s3_bucket=s3_bucket,
                src_fpath=_src_fpath,
                s3_path=_s3_path
            )


def deploy_docs(s3_bucket, s3_path, docs_dir):
    """Ship docs dir content to S3 bucket. Requires the s3 bucket to exist.

    :param s3_bucket: Name of S3 bucket. Eg: lf-project-date
    :param s3_path: Path on S3 bucket to place the docs. Eg:
        csit/${GERRIT_BRANCH}/report
    :param docs_dir: Directory in which to recursively upload content.
    :type s3_bucket: Object
    :type s3_path: str
    :type docs_dir: str
    """
    s3_resource = boto3.resource(u"s3")

    upload_recursive(
        s3_resource=s3_resource,
        s3_bucket=s3_bucket,
        src_fpath=docs_dir,
        s3_path=s3_path
    )


if __name__ == u"__main__":
    globals()[sys.argv[1]](*sys.argv[2:])

END_OF_PYTHON_SCRIPT

if [[ ${JOB_NAME} == *merge* ]]; then
    case "${JOB_NAME}" in
        *"csit-trending"*)
            SITE_DIR="${WORKSPACE}/resources/tools/trending/_build"
            s3_path="csit/${GERRIT_BRANCH}/report"
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

    echo "INFO: archiving site to S3"
    python3 $PYTHON_SCRIPT deploy_docs "fdio-docs-s3-cloudfront-index" "$s3_path" "$SITE_DIR"

    echo "S3 site: <a href=\"https://s3-docs.fd.io/$s3_path\">https://s3-docs.fd.io/$s3_path</a>"
fi
