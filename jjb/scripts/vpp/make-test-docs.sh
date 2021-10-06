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

echo "---> jjb/scripts/vpp/make-test-docs.sh"

set -euxo pipefail

# TODO: Remove this file when stable/2106 and stable/2110 are deprecated
vpp_release="$(${WORKSPACE}/build-root/scripts/version rpm-version)"
if [[ "${vpp_release::2}" -ge "22" ]] ; then
    echo "Test documentation is now generated in 'vpp-docs-*' job."
    exit 0
fi

line="*************************************************************************"
# Don't build anything if this is a merge job being run when
# the git HEAD id is not the same as the Gerrit New Revision id.
if [[ ${JOB_NAME} == *merge* ]] && [ -n "${GERRIT_NEWREV:-}" ] &&
       [ "$GERRIT_NEWREV" != "$GIT_COMMIT" ] ; then
    echo -e "\n$line\nSkipping 'make test' docs build. A newer patch has been merged.\n$line\n"
    exit 0
fi

make test-doc
