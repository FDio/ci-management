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

echo "---> jjb/scripts/backup_upload_archives.sh"

PYTHON_SCRIPT="/w/workspace/test-logs/artifact.py"

# This script uploads the artifacts to a backup upload location
if [ -f "$PYTHON_SCRIPT" ]; then
    echo "WARNING: $PYTHON_SCRIPT already exists - assume backup archive upload already done"
    exit 0
fi

# the Python code below needs boto3 installed
python3 -m pip install boto3
mkdir -p $(dirname "$PYTHON_SCRIPT")

cat >$PYTHON_SCRIPT <<'END_OF_PYTHON_SCRIPT'
#!/usr/bin/python3

"""Storage utilities library."""

import argparse
import gzip
import os
import requests
from mimetypes import MimeTypes

from boto3 import Session

ENDPOINT_URL = u"http://storage.service.consul:9000"
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


def upload(storage, bucket, src_fpath, dst_fpath):
    """Upload single file to destination bucket.

    :param storage: S3 storage resource.
    :param bucket: S3 bucket name.
    :param src_fpath: Input file path.
    :param dst_fpath: Destination file path on remote storage.
    :type storage: Object
    :type bucket: str
    :type src_fpath: str
    :type dst_fpath: str
    """
    mime_guess = MimeTypes().guess_type(src_fpath)
    mime = mime_guess[0]
    encoding = mime_guess[1]
    if not mime:
        mime = "application/octet-stream"

    if mime in COMPRESS_MIME and bucket in "logs" and encoding != "gzip":
        compress(src_fpath)
        src_fpath = src_fpath + ".gz"
        dst_fpath = dst_fpath + ".gz"

    extra_args = dict()
    extra_args['ContentType'] = mime

    storage.Bucket(bucket + ".fd.io").upload_file(
        src_fpath,
        dst_fpath,
        ExtraArgs=extra_args
    )
    print("https://" + bucket + ".nginx.service.consul/" + dst_fpath)


def upload_recursive(storage, bucket, src_fpath):
    """Recursively uploads input folder to destination.

    Example:
      - bucket: logs
      - src_fpath: /home/user
      - dst_fpath: logs.fd.io/home/user

    :param storage: S3 storage resource.
    :param bucket: S3 bucket name.
    :param src_fpath: Input folder path.
    :type storage: Object
    :type bucket: str
    :type src_fpath: str
    """
    for path, _, files in os.walk(src_fpath):
        for file in files:
            _path = path.replace(src_fpath, u"")
            _dir = src_fpath[1:] if src_fpath[0] == "/" else src_fpath
            _dst_fpath = os.path.normpath(_dir + "/" + _path + "/" + file)
            _src_fpath = os.path.join(path, file)
            upload(storage, bucket, _src_fpath, _dst_fpath)


def main():
    """Main function for storage manipulation."""

    parser = argparse.ArgumentParser()
    parser.add_argument(
        u"-d", u"--dir", required=True, type=str,
        help=u"Directory to upload to storage."
    )
    parser.add_argument(
        u"-b", u"--bucket", required=True, type=str,
        help=u"Target bucket on storage."
    )
    args = parser.parse_args()

    # Create main storage session.
    session = Session(profile_name=PROFILE_NAME)
    storage = session.resource(
        u"s3",
        endpoint_url=ENDPOINT_URL
    )

    upload_recursive(
        storage=storage,
        bucket=args.bucket,
        src_fpath=args.dir
    )


if __name__ == u"__main__":
    main()

END_OF_PYTHON_SCRIPT

WS_ARCHIVES_DIR="$WORKSPACE/archives"
TMP_ARCHIVES_DIR="/tmp/archives"
JENKINS_BUILD_ARCHIVE_DIR="$TMP_ARCHIVES_DIR/$JENKINS_HOSTNAME/$JOB_NAME/$BUILD_NUMBER"

mkdir -p $JENKINS_BUILD_ARCHIVE_DIR

if [ -e "$WS_ARCHIVES_DIR" ]; then
    echo "Found $WS_ARCHIVES_DIR, uploading its contents"
    cp -r $WS_ARCHIVES_DIR/* $JENKINS_BUILD_ARCHIVE_DIR
else
    echo "No $WS_ARCHIVES_DIR found. Creating a dummy file."
    echo "No archives found while doing backup upload" > "$JENKINS_BUILD_ARCHIVE_DIR/no-archives-found.txt"
fi

console_log="$JENKINS_BUILD_ARCHIVE_DIR/console.log"
echo "Retrieving Jenkins console log to '$console_log'"
wget -qO "$console_log" "$BUILD_URL/consoleText"

console_log="$JENKINS_BUILD_ARCHIVE_DIR/console-timestamp.log"
echo "Retrieving Jenkins console timestamp log to '$console_log'"
wget -qO "$console_log" "$BUILD_URL/timestamps?time=HH:mm:ss&appendLog"

pushd $TMP_ARCHIVES_DIR
echo "Contents of the archives dir '$TMP_ARCHIVES_DIR':"
ls -alR $TMP_ARCHIVES_DIR

# FIXME: s3 config (until migrated to vault, then account will be reset)
mkdir -p ${HOME}/.aws
echo "[fdio-logs-s3-nomad]" >> "$HOME/.aws/config"
echo "[fdio-logs-s3-nomad]
aws_access_key_id = storage
aws_secret_access_key = Storage1234" >> "$HOME/.aws/credentials"

archive_cmd="python3 $PYTHON_SCRIPT -d . -b logs"
echo -e "\nRunning uploader script '$archive_cmd':\n"
$archive_cmd || echo "Failed to upload logs"
popd
