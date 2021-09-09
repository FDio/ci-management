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

echo "---> publish_library_py.sh"

set -exuo pipefail

PYTHON_SCRIPT="/w/workspace/publish_library.py"

pip3 install boto3
mkdir -p $(dirname "$PYTHON_SCRIPT")

cat >$PYTHON_SCRIPT <<'END_OF_PYTHON_SCRIPT'
#!/usr/bin/python3

"""S3 publish library."""

import gzip
import logging
import os
import shutil
import subprocess
import sys
import tempfile
from mimetypes import MimeTypes

import boto3
from botocore.exceptions import ClientError
import requests
import six


logging.basicConfig(
    format=u"%(levelname)s: %(message)s",
    stream=sys.stdout,
    level=logging.INFO
)
logging.getLogger(u"botocore").setLevel(logging.INFO)

COMPRESS_MIME = (
    u"text/html",
    u"text/xml",
    u"text/plain",
    u"application/octet-stream"
)


def compress(src_fpath):
    """Compress a single file.

    :param src_fpath: Input file path.
    :type src_fpath: str
    """
    with open(src_fpath, u"rb") as orig_file:
        with gzip.open(src_fpath + ".gz", u"wb") as zipped_file:
            zipped_file.writelines(orig_file)


def copy_archives(workspace):
    """Copy files or directories in a $WORKSPACE/archives to the current
    directory.

    :params workspace: Workspace directery with archives directory.
    :type workspace: str
    """
    archives_dir = os.path.join(workspace, u"archives")
    dest_dir = os.getcwd()

    logging.debug(u"Copying files from " + archives_dir + u" to " + dest_dir)

    if os.path.exists(archives_dir):
        if os.path.isfile(archives_dir):
            logging.error(u"Target is a file, not a directory.")
            raise RuntimeError(u"Not a directory.")
        else:
            logging.debug("Archives dir {} does exist.".format(archives_dir))
            for file_or_dir in os.listdir(archives_dir):
                f = os.path.join(archives_dir, file_or_dir)
                try:
                    logging.debug(u"Copying " + f)
                    shutil.copy(f, dest_dir)
                except shutil.Error as e:
                    logging.error(e)
                    raise RuntimeError(u"Could not copy " + f)
    else:
        logging.error(u"Archives dir does not exist.")
        raise RuntimeError(u"Missing directory " + archives_dir)


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

    if u"logs" in s3_bucket:
        if mime in COMPRESS_MIME and encoding != u"gzip":
            compress(src_fpath)
            src_fpath = src_fpath + u".gz"
            s3_path = s3_path + u".gz"

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


def deploy_s3(s3_bucket, s3_path, build_url, workspace):
    """Add logs and archives to temp directory to be shipped to S3 bucket.
    Fetches logs and system information and pushes them and archives to S3
    for log archiving.
    Requires the s3 bucket to exist.

    :param s3_bucket: Name of S3 bucket. Eg: lf-project-date
    :param s3_path: Path on S3 bucket place the logs and archives. Eg:
        $JENKINS_HOSTNAME/$JOB_NAME/$BUILD_NUMBER
    :param build_url: URL of the Jenkins build. Jenkins typically provides this
        via the $BUILD_URL environment variable.
    :param workspace: Directory in which to search, typically in Jenkins this is
        $WORKSPACE
    :type s3_bucket: Object
    :type s3_path: str
    :type build_url: str
    :type workspace: str
    """
    s3_resource = boto3.resource(
        u"s3",
        endpoint_url=os.environ[u"AWS_ENDPOINT_URL"]
    )

    previous_dir = os.getcwd()
    work_dir = tempfile.mkdtemp(prefix="backup-s3.")
    os.chdir(work_dir)

    # Copy archive files to tmp dir.
    copy_archives(workspace)

    # Create additional build logs.
    with open(u"_build-details.log", u"w+") as f:
        f.write(u"build-url: " + build_url)

    # Magic string used to trim console logs at the appropriate level during
    # wget.
    MAGIC_STRING = u"-----END_OF_BUILD-----"
    logging.info(MAGIC_STRING)

    resp = requests.get(build_url + u"/consoleText")
    with open(u"console.log", u"w+", encoding=u"utf-8") as f:
        f.write(
            six.text_type(resp.content.decode(u"utf-8").split(MAGIC_STRING)[0])
        )

    query = u"time=HH:mm:ss&appendLog"
    resp = requests.get(build_url + u"/timestamps?" + query)
    with open(u"console-timestamp.log", u"w+", encoding=u"utf-8") as f:
        f.write(
            six.text_type(resp.content.decode(u"utf-8").split(MAGIC_STRING)[0])
        )

    upload_recursive(
        s3_resource=s3_resource,
        s3_bucket=s3_bucket,
        src_fpath=work_dir,
        s3_path=s3_path
    )

    os.chdir(previous_dir)
    shutil.rmtree(work_dir)


if __name__ == u"__main__":
    globals()[sys.argv[1]](*sys.argv[2:])

END_OF_PYTHON_SCRIPT
