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

echo "---> jjb/scripts/post_build_deploy_archives.sh"

set +e  # Do not affect the build result if some part of archiving fails.
WS_ARCHIVES_DIR="$WORKSPACE/archives"
BUILD_ENV_LOG="$WS_ARCHIVES_DIR/_build-enviroment-variables.log"

# Generate gdb-command script to output vpp stack traceback from core files.
gdb_cmdfile="/tmp/gdb-commands"
cat >$gdb_cmdfile <<'__END__'
# Usage:
# gdb $BINFILE $CORE -ex 'source -v gdb-commands' -ex quit

set pagination off
thread apply all bt

define printstack
  set $i=0
  while $i < 15
      frame $i
      x/i $pc
      info locals
      info reg
      set $i = $i + 1
  end
end
thread apply all printstack

# info proc mappings

__END__

STACKTRACE=""
# Returns stacktrace filename in STACKTRACE
generate_vpp_stacktrace_and_delete_core() {
    local corefile="$1"
    echo "Uncompressing core file $file"
    gunzip "$corefile"
    corefile="${corefile::(-3)}"
    if grep -qe 'debug' <<< "$WORKSPACE" ; then
        local binfile="$WORKSPACE/build-root/install-vpp_debug-native/vpp/bin/vpp"
    else
        local binfile="$WORKSPACE/build-root/install-vpp-native/vpp/bin/vpp"
    fi

    echo "Generating stack trace from core file: $corefile"
    STACKTRACE="${corefile}.stacktrace"
    gdb "$binfile" $corefile -ex 'source -v /tmp/gdb-commands' -ex quit > $STACKTRACE
    # remove the core to save space
    echo "Removing core file: $corefile"
    rm -f "$corefile"
    # Dump stacktrace to console log
    if [ -f "$STACKTRACE" ] ; then
        echo -e "\n=====[ $STACKTRACE ]=====\n$(cat $STACKTRACE)\n=====[ $STACKTRACE ]=====\n"
        gzip "$STACKTRACE"
    else
        echo "Stacktrace file not generated!"
        STACKTRACE=""
    fi
}

mkdir -p "$WS_ARCHIVES_DIR"

# Log the build environment variables
echo "Logging build environment variables in '$BUILD_ENV_LOG'..."
env > $BUILD_ENV_LOG

echo "ARCHIVE_ARTIFACTS = '$ARCHIVE_ARTIFACTS'"
if [ -n "${ARCHIVE_ARTIFACTS:-}" ] ; then
    pushd "$WORKSPACE"
    shopt -s globstar  # Enable globstar to copy archives
    for file in $ARCHIVE_ARTIFACTS ; do
        if [ -f "$file" ] ; then
            echo "Archiving '$file' to '$destfile'"
            destfile="$WS_ARCHIVE_DIR$file"
            destdir="$(dirname $destfile)"
            mkdir -p $destdir
            mv -f $file $destfile
        else
            echo "Not archiving '$file'"
            if ! grep -qe '*' <<<"$file" ; then
                echo "WARNING: No artifacts detected in ARCHIVE_ARTIFACTS '$ARCHIVE_ARTIFACTS'!"
            fi
        fi
    done
    shopt -u globstar  # Disable globstar
    popd
fi

# find and gzip any 'text' files
find $WS_ARCHIVES_DIR -type f -print0 \
                | xargs -0r file \
                | egrep -e ':.*text.*' \
                | cut -d: -f1 \
                | xargs -d'\n' -r gzip

# generate stack trace for VPP core files for upload instead of core file.
if [ -d "$WORKSPACE/build-root" ] ; then
    for file in $(find $WS_ARCHIVES_DIR -type f -name 'core*.gz') ; do
        generate_vpp_stacktrace_and_delete_core $file
    done
fi

# Remove any socket files in archive
find $WS_ARCHIVES_DIR -type s -exec rm -rf {} \;

echo "Workspace archived artifacts:"
ls -alR $WS_ARCHIVES_DIR
