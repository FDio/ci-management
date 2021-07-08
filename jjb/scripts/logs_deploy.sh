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

# shellcheck disable=SC1090
source ~/lf-env.sh
lf-activate-venv lftools

CDN_URL="logs.nginx.service.consul"

# FIXME: s3 config (until migrated to config provider, then pwd will be reset)
mkdir -p ${HOME}/.aws
echo "[default]
aws_access_key_id = storage
aws_secret_access_key = Storage1234" >> "$HOME/.aws/credentials"

PYTHON_SCRIPT="/w/workspace/test-logs/artifact.py"

# This script uploads the artifacts to a backup upload location
if [ -f "$PYTHON_SCRIPT" ]; then
    echo "WARNING: $PYTHON_SCRIPT already exists - assume backup archive upload already done"
    exit 0
fi

mkdir -p $(dirname "$PYTHON_SCRIPT")

cat >$PYTHON_SCRIPT <<'END_OF_PYTHON_SCRIPT'
#!/usr/bin/python3


import concurrent.futures
import errno
import glob
import gzip
import io
import logging
import math
import mimetypes
import os
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile

import boto3
from botocore.exceptions import ClientError
import requests
import six

log = logging.getLogger(__name__)
logging.getLogger("botocore").setLevel(logging.CRITICAL)


def _compress_text(dir):
    """Compress all text files in directory."""
    save_dir = os.getcwd()
    os.chdir(dir)

    compress_types = [
        "**/*.html",
        "**/*.log",
        "**/*.txt",
        "**/*.xml",
    ]
    paths = []
    for _type in compress_types:
        search = os.path.join(dir, _type)
        paths.extend(glob.glob(search, recursive=True))

    for _file in paths:
        # glob may follow symlink paths that open can't find
        if os.path.exists(_file):
            log.debug("Compressing file {}".format(_file))
            with open(_file, "rb") as src, gzip.open("{}.gz".format(_file), "wb") as dest:
                shutil.copyfileobj(src, dest)
                os.remove(_file)
        else:
            log.info("Could not open path from glob {}".format(_file))

    os.chdir(save_dir)


def _format_url(url):
    """Ensure url starts with http and trim trailing '/'s."""
    start_pattern = re.compile("^(http|https)://")
    if not start_pattern.match(url):
        url = "http://{}".format(url)

    if url.endswith("/"):
        url = url.rstrip("/")

    return url


def _remove_duplicates_and_sort(lst):
    # Remove duplicates from list, and sort it
    no_dups_lst = list(dict.fromkeys(lst))
    no_dups_lst.sort()

    duplicated_list = []
    for i in range(len(no_dups_lst)):
        if lst.count(no_dups_lst[i]) > 1:
            duplicated_list.append(no_dups_lst[i])
    log.debug("duplicates  : {}".format(duplicated_list))

    return no_dups_lst


def copy_archives(workspace, pattern=None):
    """Copy files matching PATTERN in a WORKSPACE to the current directory.
    The best way to use this function is to cd into the directory you wish to
    store the files first before calling the function.
    This function provides 2 ways to archive files:
        1) copy $WORKSPACE/archives directory
        2) copy globstar pattern
    :params:
        :arg str pattern: Space-separated list of Unix style glob patterns.
            (default: None)
    """
    archives_dir = os.path.join(workspace, "archives")
    dest_dir = os.getcwd()

    log.debug("Copying files from {} with pattern '{}' to {}.".format(workspace, pattern, dest_dir))
    log.debug("archives_dir = {}".format(archives_dir))

    if os.path.exists(archives_dir):
        if os.path.isfile(archives_dir):
            log.error("Archives {} is a file, not a directory.".format(archives_dir))
            raise OSError(errno.ENOENT, "Not a directory", archives_dir)
        else:
            log.debug("Archives dir {} does exist.".format(archives_dir))
            for file_or_dir in os.listdir(archives_dir):
                f = os.path.join(archives_dir, file_or_dir)
                try:
                    log.debug("Moving {}".format(f))
                    shutil.move(f, dest_dir)
                except shutil.Error as e:
                    log.error(e)
                    raise OSError(errno.EPERM, "Could not move to", archives_dir)
    else:
        log.error("Archives dir {} does not exist.".format(archives_dir))
        raise OSError(errno.ENOENT, "Missing directory", archives_dir)

    if pattern is None:
        return

    no_dups_pattern = _remove_duplicates_and_sort(pattern)

    paths = []
    for p in no_dups_pattern:
        if p == "":  # Skip empty patterns as they are invalid
            continue

        search = os.path.join(workspace, p)
        paths.extend(glob.glob(search, recursive=True))
    log.debug("Files found: {}".format(paths))

    no_dups_paths = _remove_duplicates_and_sort(paths)

    for src in no_dups_paths:
        if len(os.path.basename(src)) > 255:
            log.warn("Filename {} is over 255 characters. Skipping...".format(os.path.basename(src)))

        dest = os.path.join(dest_dir, src[len(workspace) + 1 :])
        log.debug("{} -> {}".format(src, dest))

        if os.path.isfile(src):
            try:
                shutil.move(src, dest)
            except IOError as e:  # Switch to FileNotFoundError when Python 2 support is dropped.
                log.debug("Missing path, will create it {}.\n{}".format(os.path.dirname(dest), e))
                os.makedirs(os.path.dirname(dest))
                shutil.move(src, dest)
        else:
            log.info("Not copying directories: {}.".format(src))


def deploy_s3(s3_bucket, s3_path, build_url, workspace, pattern=None):
    """Add logs and archives to temp directory to be shipped to S3 bucket.
    Fetches logs and system information and pushes them and archives to S3
    for log archiving.
    Requires the s3 bucket to exist.
    Parameters:
        :s3_bucket: Name of S3 bucket. Eg: lf-project-date
        :s3_path: Path on S3 bucket place the logs and archives. Eg:
            $SILO/$JENKINS_HOSTNAME/$JOB_NAME/$BUILD_NUMBER
        :build_url: URL of the Jenkins build. Jenkins typically provides this
                    via the $BUILD_URL environment variable.
        :workspace: Directory in which to search, typically in Jenkins this is
            $WORKSPACE
        :pattern: Space-separated list of Globstar patterns of files to
            archive. (optional)
    """

    def _upload_to_s3(file):
        extra_args = {"ContentType": "application/octet-stream"}
        text_plain_extra_args = {"ContentType": "application/octet-stream", "ContentEncoding": mimetypes.guess_type(file)[1]}
        app_xml_extra_args = {"ContentType": "application/xml'", "ContentEncoding": mimetypes.guess_type(file)[1]}
        if file == "_tmpfile":
            for dir in (logs_dir, silo_dir, jenkins_node_dir):
                try:
                    s3.Bucket(s3_bucket).upload_file(file, "{}{}".format(dir, file))
                except ClientError as e:
                    log.error(e)
                    return False
                return True
        if mimetypes.guess_type(file)[0] is None and mimetypes.guess_type(file)[1] is None:
            try:
                s3.Bucket(s3_bucket).upload_file(file, "{}{}".format(s3_path, file), ExtraArgs=extra_args)
            except ClientError as e:
                log.error(e)
                return False
            return True
        elif mimetypes.guess_type(file)[0] is None or mimetypes.guess_type(file)[0] in "text/plain":
            extra_args = text_plain_extra_args
            try:
                s3.Bucket(s3_bucket).upload_file(file, "{}{}".format(s3_path, file), ExtraArgs=extra_args)
            except ClientError as e:
                log.error(e)
                return False
            return True
        elif mimetypes.guess_type(file)[0] in "application/xml":
            extra_args = app_xml_extra_args
            try:
                s3.Bucket(s3_bucket).upload_file(file, "{}{}".format(s3_path, file), ExtraArgs=extra_args)
            except ClientError as e:
                log.error(e)
                return False
            return True
        else:
            try:
                s3.Bucket(s3_bucket).upload_file(file, "{}{}".format(s3_path, file), ExtraArgs=extra_args)
            except ClientError as e:
                log.error(e)
                return False
            return True

    previous_dir = os.getcwd()
    work_dir = tempfile.mkdtemp(prefix="lftools-dl.")
    os.chdir(work_dir)
    s3_bucket = s3_bucket.lower()
    s3 = boto3.resource("s3", endpoint_url="http://storage.service.consul:9000")
    logs_dir = s3_path.split("/")[0] + "/"
    silo_dir = s3_path.split("/")[1] + "/"
    jenkins_node_dir = logs_dir + silo_dir + s3_path.split("/")[2] + "/"

    log.debug("work_dir: {}".format(work_dir))

    # Copy archive files to tmp dir
    copy_archives(workspace, pattern)

    # Create build logs
    build_details = open("_build-details.log", "w+")
    build_details.write("build-url: {}".format(build_url))

    with open("_sys-info.log", "w+") as sysinfo_log:
        sys_cmds = []

        log.debug("Platform: {}".format(sys.platform))
        if sys.platform == "linux" or sys.platform == "linux2":
            sys_cmds = [
                ["uname", "-a"],
                ["lscpu"],
                ["nproc"],
                ["df", "-h"],
                ["free", "-m"],
                ["ip", "addr"],
                ["sar", "-b", "-r", "-n", "DEV"],
                ["sar", "-P", "ALL"],
            ]

        for c in sys_cmds:
            try:
                output = subprocess.check_output(c).decode("utf-8")
            except FileNotFoundError:
                log.debug("Command not found: {}".format(c))
                continue

            output = "---> {}:\n{}\n".format(" ".join(c), output)
            sysinfo_log.write(output)
            log.info(output)

    build_details.close()
    sysinfo_log.close()

    # Magic string used to trim console logs at the appropriate level during wget
    MAGIC_STRING = "-----END_OF_BUILD-----"
    log.info(MAGIC_STRING)

    resp = requests.get("{}/consoleText".format(_format_url(build_url)))
    with open("console.log", "w+", encoding="utf-8") as f:
        f.write(six.text_type(resp.content.decode("utf-8").split(MAGIC_STRING)[0]))
        f.close()

    resp = requests.get("{}/timestamps?time=HH:mm:ss&appendLog".format(_format_url(build_url)))
    with open("console-timestamp.log", "w+", encoding="utf-8") as f:
        f.write(six.text_type(resp.content.decode("utf-8").split(MAGIC_STRING)[0]))
        f.close()

    # Create _tmpfile
    """ Because s3 does not have a filesystem, this file is uploaded to generate/update the
        index.html file in the top level "directories". """
    open("_tmpfile", "a").close()

    # Compress tmp directory
    _compress_text(work_dir)

    # Create file list to upload
    file_list = []
    files = glob.glob("**/*", recursive=True)
    for file in files:
        if os.path.isfile(file):
            file_list.append(file)

    log.info("#######################################################")
    log.info("Deploying files from {} to {}/{}".format(work_dir, s3_bucket, s3_path))

    # Perform s3 upload
    for file in file_list:
        log.info("Attempting to upload file {}".format(file))
        if _upload_to_s3(file):
            log.info("Successfully uploaded {}".format(file))
        else:
            log.error("FAILURE: Uploading {} failed".format(file))

    log.info("Finished deploying from {} to {}/{}".format(work_dir, s3_bucket, s3_path))
    log.info("#######################################################")

    os.chdir(previous_dir)

if __name__ == '__main__':
    args = sys.argv
    globals()[args[1]](*args[2:])

END_OF_PYTHON_SCRIPT

# The 'lftool deploy archives' command below expects the archives
# directory to exist.  Normally lf-infra-sysstat or similar would
# create it and add content, but to make sure this script is
# self-contained, we ensure it exists here.
mkdir -p "$WORKSPACE/archives"

get_pattern_opts () {
    opts=()
    for arg in ${ARCHIVE_ARTIFACTS:-}; do
        opts+=("-p" "$arg")
    done
    echo "${opts[@]-}"
}

pattern_opts=$(get_pattern_opts)

s3_path="$JENKINS_HOSTNAME/$JOB_NAME/$BUILD_NUMBER/"
echo "INFO: S3 path $s3_path"

echo "INFO: archiving backup logs to S3"
# shellcheck disable=SC2086
python3 $PYTHON_SCRIPT deploy_s3 "logs.fd.io" "$s3_path" \
    "$BUILD_URL" "$WORKSPACE"

echo "S3 build logs: <a href=\"https://$CDN_URL/$s3_path\">https://$CDN_URL/$s3_path</a>"
