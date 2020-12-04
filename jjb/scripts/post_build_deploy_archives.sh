#!/bin/bash

# Copyright (c) 2020 Cisco and/or its affiliates.
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

echo "---> jjb/scripts/post_build_deploy_archives.sh"

set +e  # Do not affect the build result if some part of archiving fails.
WS_ARCHIVES_DIR="$WORKSPACE/archives"
BUILD_ENV_LOG="$WS_ARCHIVES_DIR/_build-enviroment-variables.log"

# Log the build environment variables
echo "Logging build environment variables in '$BUILD_ENV_LOG'..."
mkdir -p $WS_ARCHIVES_DIR
env > $BUILD_ENV_LOG

echo "WS_ARCHIVE_ARTIFACTS = '$WS_ARCHIVE_ARTIFACTS'"
if [ ! -z "${WS_ARCHIVE_ARTIFACTS}" ]; then
    pushd $WORKSPACE
    shopt -s globstar  # Enable globstar to copy archives
    archive_artifacts=$(echo ${WS_ARCHIVE_ARTIFACTS})
    for file in $archive_artifacts; do
        if [ -f "$file" ] ; then
            echo "Archiving '$file'..."
            mkdir -p $WS_ARCHIVES_DIR/$(dirname $file)
            mv $file $WS_ARCHIVES_DIR/$file
        else
            echo "Skipping '$file' which is not a file:"
            ls -ld $file
        fi
    done
    shopt -u globstar  # Disable globstar once archives are copied
    popd
    # Clean up failed 'make test' archive directories for better
    # navigation and legibility of log directories.
    if [ -d "$WS_ARCHIVES_DIR/tmp" ] ; then
        mv $WS_ARCHIVES_DIR/tmp/* $WS_ARCHIVES_DIR
        rmdir $WS_ARCHIVES_DIR/tmp
    fi
fi

# find and gzip any 'text' files
find $WS_ARCHIVES_DIR -type f -print0 \
                | xargs -0r file \
                | egrep -e ':.*text.*' \
                | cut -d: -f1 \
                | xargs -d'\n' -r gzip
