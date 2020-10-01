#!/bin/bash
echo "---> jjb/scripts/packagecloud_push.sh"

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

# PCIO_CO and SILO are Jenkins Global Environment variables defined in
# .../ci-management/jenkins-config/global-vars-*.sh

set -x

if [ "$SILO" = "sandbox" ] ; then
    echo "SANDBOX: Pretending to push to PackageCloud..."
    sleep 1
    echo "SANDBOX: Simulated PackageCloud push complete!"
    exit 0
fi

echo "STARTING PACKAGECLOUD PUSH"

sleep 10

FACTER_OS=$(/usr/bin/facter operatingsystem)

if [ -f ~/.packagecloud ]; then
    case "$FACTER_OS" in
      Ubuntu)
        FACTER_LSBNAME=$(/usr/bin/facter lsbdistcodename)
        DEBS=$(find . -type f -iname '*.deb')
        package_cloud push "${PCIO_CO}/${STREAM}/ubuntu/${FACTER_LSBNAME}/main/" ${DEBS}
      ;;
      CentOS)
        FACTER_OSMAJREL=$(/usr/bin/facter operatingsystemmajrelease)
        FACTER_ARCH=$(/usr/bin/facter architecture)
        RPMS=$(find . -type f -iregex '.*/.*\.\(s\)?rpm')
        package_cloud push "${PCIO_CO}/${STREAM}/el/${FACTER_OSMAJREL}/os/${FACTER_ARCH}/" ${RPMS}
      ;;
    esac
fi
