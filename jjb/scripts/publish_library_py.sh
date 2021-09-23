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

import glob
import gzip
import logging
import os
import shutil
import subprocess
import sys
import tempfile

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


FILE_TYPE = {
    u"xml": u"application/xml",
    u"html": u"text/html",
    u"txt": u"text/plain",
    u"log": u"text/plain",
    u"css": u"text/css",
    u"md": u"text/markdown",
    u"rst": u"text/x-rst",
    u"csv": u"text/csv",
    u"svg": u"image/svg+xml",
    u"jpg": u"image/jpeg",
    u"png": u"image/png",
    u"gif": u"image/gif",
    u"js": u"application/javascript",
    u"pdf": u"application/pdf",
    u"json": u"application/json",
    u"otf": u"font/otf",
    u"ttf": u"font/ttf",
    u"woff": u"font/woff",
    u"woff2": u"font/woff2"
}


COMPRESS_TYPES = (
    "**/*.html",
    "**/*.log",
    "**/*.txt",
    "**/*.xml",
    "**/*.json",
)


def compress_text(src_dpath):
    """Compress all text files in directory.

    :param src_dpath: Input dir path.
    :type src_dpath: str
    """
    save_dir = os.getcwd()
    os.chdir(src_dpath)

    paths = list()
    for _type in COMPRESS_TYPES:
        search = os.path.join(src_dpath, _type)
        paths.extend(glob.glob(search, recursive=True))

    for _file in paths:
        # glob may follow symlink paths that open can't find
        if os.path.exists(_file):
            gz_file = u"{}.gz".format(_file)
            with open(_file, "rb") as src, gzip.open(gz_file, "wb") as dest:
                shutil.copyfileobj(src, dest)
                os.remove(_file)

    os.chdir(save_dir)


def copy_archives(workspace):
    """Copy files or directories in a \$WORKSPACE/archives to the current
    directory.

    :params workspace: Workspace directery with archives directory.
    :type workspace: str
    """
    archives_dir = os.path.join(workspace, u"archives")
    dest_dir = os.getcwd()

    logging.debug(u"Copying files from " + archives_dir + u" to " + dest_dir)

    if not os.path.exists(archives_dir):
        logging.error(u"Archives dir does not exist.")
        raise RuntimeError(u"Missing directory " + archives_dir)
    if os.path.isfile(archives_dir):
        logging.error(u"Target is a file, not a directory.")
        raise RuntimeError(u"Not a directory.")
    logging.debug("Archives dir {} does exist.".format(archives_dir))
    for item in os.listdir(archives_dir):
        src = os.path.join(archives_dir, item)
        dst = os.path.join(dest_dir, item)
        try:
            if os.path.isdir(src):
                shutil.copytree(src, dst, symlinks=False, ignore=None)
            else:
                shutil.copy2(src, dst)
        except shutil.Error as e:
            logging.error(e)
            raise RuntimeError(u"Could not copy " + src)


def is_gzip_file(filepath):
    """Retrun whether the file is gzipped.

    Do not trust the extension, look at first two bytes to decide.

    :param filepath: Path to the file to be checked.
    :type filepath: Union[str, os.PathLike]
    :returns: True if it is gzipped, False otherwise.
    :rtype: bool
    :raises OSError: Various subclasses depending on how open() failed.
    """
    with open(filepath, u"rb") as test_f:
        return test_f.read(2) == b"\x1f\x8b"


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
    if os.path.isdir(src_fpath):
        return
    if not os.path.isfile(src_fpath):
        # TODO: Print some warning?
        return

    extra_args = dict()
    file_name, file_extension = os.path.splitext(src_fpath)
    if is_gzip_file(src_fpath):
        extra_args[u"ContentEncoding"] = "gzip"
        file_name, file_extension = os.path.splitext(file_name)
    extra_args[u"ContentType"] = FILE_TYPE.get(
        file_extension.strip("."), u"application/octet-stream"
    )

    try:
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
        for _file in files:
            _path = path.replace(src_fpath, u"")
            _src_fpath = os.path.join(path, _file)
            _s3_path = os.path.normpath(os.path.join(s3_path, _path, _file))
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
        csit/\${GERRIT_BRANCH}/report
    :param docs_dir: Directory in which to recursively upload content.
    :type s3_bucket: Object
    :type s3_path: str
    :type docs_dir: str
    """
    try:
        s3_resource = boto3.resource(
            u"s3",
            endpoint_url=os.environ[u"AWS_ENDPOINT_URL"]
        )
    except KeyError:
        s3_resource = boto3.resource(
            u"s3"
        )

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
        \$JENKINS_HOSTNAME/\$JOB_NAME/\$BUILD_NUMBER
    :param build_url: URL of the Jenkins build. Jenkins typically provides this
        via the \$BUILD_URL environment variable.
    :param workspace: Directory in which to search, typically in Jenkins this is
        \$WORKSPACE
    :type s3_bucket: Object
    :type s3_path: str
    :type build_url: str
    :type workspace: str
    """
    try:
        s3_resource = boto3.resource(
            u"s3",
            endpoint_url=os.environ[u"AWS_ENDPOINT_URL"]
        )
    except KeyError:
        s3_resource = boto3.resource(
            u"s3"
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

    compress_text(work_dir)

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
