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

echo "---> jjb/scripts/csit/cpta.sh"

set -xe -o pipefail

[ "${DOCS_REPO_URL}" ] || DOCS_REPO_URL="https://nexus.fd.io/content/sites/site"
[ "${PROJECT_PATH}" ] || PROJECT_PATH="io/fd/csit"
[ "${DOC_DIR}" ] || DOC_DIR="resources/tools/presentation"
[ "${BUILD_DIR}" ] || BUILD_DIR="${DOC_DIR}/_build"
[ "${SITE_DIR}" ] || SITE_DIR="build-root/docs/deploy-site"
[ "${RESOURCES_DIR}" ] || RESOURCES_DIR="${SITE_DIR}/src/site/resources/trending"
[ "${STATIC_VPP_DIR}" ] || STATIC_VPP_DIR="${RESOURCES_DIR}/_static/vpp"
[ "${MVN}" ] || MVN="/opt/apache/maven/bin/mvn"
[ "${FAILED_TESTS}" ] || FAILED_TESTS="${STATIC_VPP_DIR}/trending-failed-tests.txt"
[ "${REGRESSIONS}" ] || REGRESSIONS="${STATIC_VPP_DIR}/trending-regressions.txt"
[ "${PROGRESSIONS}" ] || PROGRESSIONS="${STATIC_VPP_DIR}/trending-progressions.txt"

# Create a text file with email body in case the build fails:
cd "${WORKSPACE}"
mkdir -p "${STATIC_VPP_DIR}"
EMAIL_BODY="ERROR: The build number ${BUILD_NUMBER} of the job ${JOB_NAME} failed. For more information see: ${BUILD_URL}"
echo "${EMAIL_BODY}" > "${FAILED_TESTS}"
echo "${EMAIL_BODY}" > "${REGRESSIONS}"
echo "${EMAIL_BODY}" > "${PROGRESSIONS}"

cd "${DOC_DIR}"
chmod +x ./run_cpta.sh
STATUS=$(./run_cpta.sh | tail -1)

cd "${WORKSPACE}"
rm -rf "${SITE_DIR}/"*

mkdir -p "${RESOURCES_DIR}"
ls "${RESOURCES_DIR}"
mv -f "${BUILD_DIR}/"* "${RESOURCES_DIR}"

cd "${SITE_DIR}"

cat > pom.xml << EOF
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>io.fd.csit</groupId>
    <artifactId>docs</artifactId>
    <version>1.0.0</version>
    <packaging>pom</packaging>
    <properties>
        <generateReports>false</generateReports>
    </properties>
    <build>
        <extensions>
            <extension>
                <groupId>org.apache.maven.wagon</groupId>
                <artifactId>wagon-webdav-jackrabbit</artifactId>
                <version>2.10</version>
            </extension>
        </extensions>
    </build>
    <distributionManagement>
        <site>
            <id>fdio-site</id>
            <url>dav:${DOCS_REPO_URL}/${PROJECT_PATH}/${GERRIT_BRANCH}</url>
        </site>
    </distributionManagement>
</project>
EOF

${MVN} -B site:site site:deploy -gs "${GLOBAL_SETTINGS_FILE}" -s "${SETTINGS_FILE}" -T 4C

cd -

if [ "${STATUS}" == "PASS" ]; then
    exit 0
else
    exit 1
fi
