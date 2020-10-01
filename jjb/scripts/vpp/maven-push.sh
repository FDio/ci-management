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

echo "---> jjb/scripts/vpp/maven-push.sh"

set -xe -o pipefail
echo "*******************************************************************"
echo "* STARTING PUSH OF PACKAGES TO REPOS"
echo "* NOTHING THAT HAPPENS BELOW THIS POINT IS RELATED TO BUILD FAILURE"
echo "*******************************************************************"

[ "$MVN" ] || MVN="/opt/apache/maven/bin/mvn"
GROUP_ID="io.fd.${PROJECT}"
BASEURL="${NEXUSPROXY}/content/repositories/fd.io."
BASEREPOID='fdio-'

if [ "${OS}" == "ubuntu1604" ]; then
    # Find the files
    JARS=$(find . -type f -iname '*.jar')
    DEBS=$(find . -type f -iname '*.deb')
    for i in $JARS
    do
        push_jar "$i"
    done

    for i in $DEBS
    do
        push_deb "$i"
    done
elif [ "${OS}" == "ubuntu1804" ]; then
    # Find the files
    JARS=$(find . -type f -iname '*.jar')
    DEBS=$(find . -type f -iname '*.deb')
    for i in $JARS
    do
        push_jar "$i"
    done

    for i in $DEBS
    do
        push_deb "$i"
    done
elif [ "${OS}" == "centos7" ]; then
    # Find the files
    RPMS=$(find . -type f -iname '*.rpm')
    SRPMS=$(find . -type f -iname '*.srpm')
    SRCRPMS=$(find . -type f -name '*.src.rpm')
    for i in $RPMS $SRPMS $SRCRPMS
    do
        push_rpm "$i"
    done
fi
# vim: ts=4 sw=4 sts=4 et ft=sh :
