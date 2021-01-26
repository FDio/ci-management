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

echo "---> jjb/scripts/packagecloud_push.sh"

set -euxo pipefail

line="*************************************************************************"

# Nothing was built if this is a merge job being run when
# the git HEAD id is not the same as the Gerrit New Revision ID
if [[ ${JOB_NAME} == *merge* ]] && [ -n "${GERRIT_NEWREV:-}" ] &&
       [ "$GERRIT_NEWREV" != "$GIT_COMMIT" ] ; then
    echo -e "\n$line\nSkipping package push. A newer patch has been merged.\n$line\n"
    exit 0
fi

echo "STARTING PACKAGECLOUD PUSH"

sleep 10

FACTER_OS=$(/usr/bin/facter operatingsystem)
push_cmd=""
push_ext_deps_cmd=""

# PCIO_CO and SILO are Jenkins Global Environment variables defined in
# .../ci-management/jenkins-config/global-vars-*.sh
if [ -f ~/.packagecloud ]; then
    case "$FACTER_OS" in
        Debian)
            FACTER_LSBNAME=$(/usr/bin/facter lsbdistcodename)
            DEBS=$(find . -type f -iname '*.deb' | grep -v vpp-ext-deps)
            push_cmd="package_cloud push ${PCIO_CO}/${STREAM}/debian/${FACTER_LSBNAME}/main/ ${DEBS}"
            EXT_DEPS_DEB=$(find . -type f -iname 'vpp-ext-deps*.deb')
            if [ -n "$EXT_DEPS_DEB" ] ; then
                push_ext_deps_cmd="package_cloud push ${PCIO_CO}/${STREAM}/debian/${FACTER_LSBNAME}/main/ ${EXT_DEPS_DEB}"
            fi
            ;;
        Ubuntu)
            FACTER_LSBNAME=$(/usr/bin/facter lsbdistcodename)
            DEBS=$(find . -type f -iname '*.deb' | grep -v vpp-ext-deps)
            push_cmd="package_cloud push ${PCIO_CO}/${STREAM}/ubuntu/${FACTER_LSBNAME}/main/ ${DEBS}"
            EXT_DEPS_DEB=$(find . -type f -iname 'vpp-ext-deps*.deb')
            if [ -n "$EXT_DEPS_DEB" ] ; then
                push_ext_deps_cmd="package_cloud push ${PCIO_CO}/${STREAM}/ubuntu/${FACTER_LSBNAME}/main/ ${EXT_DEPS_DEB}"
            fi
            ;;
        CentOS)
            FACTER_OSMAJREL=$(/usr/bin/facter operatingsystemmajrelease)
            FACTER_ARCH=$(/usr/bin/facter architecture)
            RPMS=$(find . -type f -iregex '.*/.*\.\(s\)?rpm' | grep -v vpp-ext-deps)
            push_cmd="package_cloud push ${PCIO_CO}/${STREAM}/el/${FACTER_OSMAJREL}/os/${FACTER_ARCH}/ ${RPMS}"
            EXT_DEPS_RPM=$(find . -type f -iname 'vpp-ext-deps*.rpm')
            if [ -n "$EXT_DEPS_RPM" ] ; then
                push_ext_deps_cmd="package_cloud push ${PCIO_CO}/${STREAM}/el/${FACTER_OSMAJREL}/os/${FACTER_ARCH}/ ${EXT_DEPS_RPM}"
            fi
            ;;
        *)
            echo -e "\n$line\n* ERROR: Unsupported OS '$FACTER_OS'\n* PACKAGECLOUD PUSH FAILED!\n$line\n"
            exit 1
            ;;
    esac
    if [ "${SILO,,}" = "sandbox" ] ; then
        echo "SANDBOX: skipping '$push_cmd'"
        if [ -n "$push_ext_deps_cmd" ] ; then
            echo "SANDBOX: skipping '$push_ext_deps_cmd'"
        fi
    else
        $push_cmd
        if [ -n "$push_ext_deps_cmd" ] ; then
            # Don't fail script if vpp-ext-deps push fails.
            set +e
            $push_ext_deps_cmd
            set -e
        fi
    fi
else
    echo "ERROR: Missing '~/.packagecloud' for user '$(id)'"
    echo "PACKAGECLOUD PUSH FAILED!"
    exit 1
fi

echo -e "\n$line\n* PACKAGECLOUD PUSH COMPLETE\n$line\n"
