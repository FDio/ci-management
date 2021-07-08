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

echo "---> logs_deploy.sh"

CDN_URL="logs.nginx.service.consul"

# FIXME: s3 config (until migrated to config provider, then pwd will be reset)
mkdir -p ${HOME}/.aws
echo "[default]
aws_access_key_id = storage
aws_secret_access_key = Storage1234" >> "$HOME/.aws/credentials"

PYTHON_SCRIPT="/w/workspace/test-logs/logs_deploy.py"

# This script uploads the artifacts to a backup upload location
if [ -f "$PYTHON_SCRIPT" ]; then
    echo "WARNING: $PYTHON_SCRIPT already exists - assume backup archive upload already done"
    exit 0
fi

mkdir -p $(dirname "$PYTHON_SCRIPT")

cat >$PYTHON_SCRIPT <<'END_OF_PYTHON_SCRIPT'
#!/usr/bin/python3

"""Storage utilities library."""

import gzip
import logging
import os
import re
import subprocess
import sys
from mimetypes import MimeTypes

import boto3
from botocore.exceptions import ClientError
import requests
import six

log = logging.getLogger(__name__)
logging.getLogger(u"botocore").setLevel(logging.INFO)


COMPRESS_MIME = (
    u"text/html",
    u"text/xml",
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


def format_url(url):
    """Ensure URL starts with http and trim trailing '/'s.

    :param url: URL to format.
    :type url: str
    :returns: URI formatted string.
    :rtype: str
    """
    start_pattern = re.compile(r"^(http|https)://")
    if not start_pattern.match(url):
        url = u"http://{url}"
    if url.endswith(u"/"):
        url = url.rstrip(u"/")
    return url


def upload(s3_resource, s3_bucket, src_fpath, dst_fpath):
    """Upload single file to destination bucket.

    :param s3_resource: S3 storage resource.
    :param s3_bucket: S3 bucket name.
    :param src_fpath: Input file path.
    :param dst_fpath: Destination file path on remote storage.
    :type s3_resource: Object
    :type s3_bucket: str
    :type src_fpath: str
    :type dst_fpath: str
    :returns: True if success, False if error.
    :rtype: bool
    """
    mime_guess = MimeTypes().guess_type(src_fpath)
    mime = mime_guess[0]
    encoding = mime_guess[1]
    if not mime:
        mime = u"application/octet-stream"

    if mime in COMPRESS_MIME and s3_bucket in u"logs" and encoding != u"gzip":
        compress(src_fpath)
        src_fpath = src_fpath + u".gz"
        dst_fpath = dst_fpath + u".gz"

    extra_args = {u"ContentType": u"application/octet-stream"}

    try:
        s3_resource.Bucket(s3_bucket).upload_file(
            src_fpath, dst_fpath, ExtraArgs=extra_args
        )
        log.info(u"https://logs.nginx.service.consul/" + dst_fpath)
    except ClientError as e:
        log.error(e)
        return False

    return True


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
            _dst_fpath = os.path.normpath(s3_path + u"/" + _path + u"/" + file)
            _src_fpath = path
            upload(s3_resource, s3_bucket, _src_fpath, _dst_fpath)


def deploy_s3(s3_bucket, s3_path, build_url, workspace):
    """Add logs and archives to temp directory to be shipped to S3 bucket.
    Fetches logs and system information and pushes them and archives to S3
    for log archiving.
    Requires the s3 bucket to exist.

    :param s3_bucket: Name of S3 bucket. Eg: lf-project-date
    :param s3_path: Path on S3 bucket place the logs and archives. Eg:
        $SILO/$JENKINS_HOSTNAME/$JOB_NAME/$BUILD_NUMBER
    :param build_url: URL of the Jenkins build. Jenkins typically provides this
        via the $BUILD_URL environment variable.
    :param workspace: Directory in which to search, typically in Jenkins this is
        $WORKSPACE
    """
    s3_resource = boto3.resource(
        u"s3",
        endpoint_url=u"http://storage.service.consul:9000"
    )

    # Create build logs
    with open(u"_build-details.log", u"w+") as f:
        f.write(u"build-url: " + build_url)

    with open(u"_sys-info.log", u"w+") as f:
        sys_cmds = []

        log.debug(u"Platform: " + sys.platform)
        if sys.platform == u"linux" or sys.platform == u"linux2":
            sys_cmds = [
                [u"uname", u"-a"],
                [u"lscpu"],
                [u"nproc"],
                [u"df", u"-h"],
                [u"free", u"-m"],
                [u"ip", u"addr"],
                [u"sar", u"-b", u"-r", u"-n", u"DEV"],
                [u"sar", u"-P", u"ALL"],
            ]

        for c in sys_cmds:
            try:
                output = subprocess.check_output(c).decode(u"utf-8")
            except FileNotFoundError:
                log.debug(u"Command not found: " + c)
                continue

            cmd = u" ".join(c)
            output = u"---> " + cmd + "\n" + output + "\n"
            f.write(output)
            log.info(output)

    # Magic string used to trim console logs at the appropriate level during wget
    MAGIC_STRING = u"-----END_OF_BUILD-----"
    log.info(MAGIC_STRING)

    resp = requests.get(format_url(build_url) + u"/consoleText")
    with open(u"console.log", u"w+", encoding=u"utf-8") as f:
        f.write(
            six.text_type(resp.content.decode(u"utf-8").split(MAGIC_STRING)[0])
        )

    query = u"time=HH:mm:ss&appendLog"
    resp = requests.get(format_url(build_url) + u"/timestamps?" + query)
    with open(u"console-timestamp.log", u"w+", encoding=u"utf-8") as f:
        f.write(
            six.text_type(resp.content.decode(u"utf-8").split(MAGIC_STRING)[0])
        )

    upload_recursive(
        s3_resource=s3_resource,
        s3_bucket=s3_bucket,
        src_fpath=workspace,
        s3_path=s3_path
    )


if __name__ == u"__main__":
    globals()[sys.argv[1]](*sys.argv[2:])

END_OF_PYTHON_SCRIPT

# The 'deploy_s3' command below expects the archives
# directory to exist.  Normally lf-infra-sysstat or similar would
# create it and add content, but to make sure this script is
# self-contained, we ensure it exists here.
mkdir -p "$WORKSPACE/archives"

s3_path="$JENKINS_HOSTNAME/$JOB_NAME/$BUILD_NUMBER/"
echo "INFO: S3 path $s3_path"

echo "INFO: archiving backup logs to S3"
# shellcheck disable=SC2086
python3 $PYTHON_SCRIPT deploy_s3 "logs.fd.io" "$s3_path" \
    "$BUILD_URL" "$WORKSPACE"

echo "S3 build backup logs: <a href=\"https://$CDN_URL/$s3_path\">https://$CDN_URL/$s3_path</a>"
