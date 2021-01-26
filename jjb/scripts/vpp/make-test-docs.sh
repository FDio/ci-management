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

line="*************************************************************************"
# Don't build anything if this is a merge job being run when
# the git HEAD id is not the same as the Gerrit New Revision id.
if [[ ${JOB_NAME} == *merge* ]] && [ -n "${GERRIT_NEWREV:-}" ] &&
       [ "$GERRIT_NEWREV" != "$GIT_COMMIT" ] ; then
    echo -e "\n$line\nSkipping 'make test' doxygen docs build. A newer patch has been merged.\n$line\n"
    exit 0
fi

DOCS_REPO_URL=${DOCS_REPO_URL:-"https://nexus.fd.io/content/sites/site"}
PROJECT_PATH=${PROJECT_PATH:-"io/fd/vpp"}
DOC_DIR=${DOC_DIR:-"build-root/build-test/doc/html"}
SITE_DIR=${SITE_DIR:-"build-root/docs/deploy-site"}
RESOURCES_DIR=${RESOURCES_DIR:-"${SITE_DIR}/src/site/resources/vpp_make_test"}
MVN=${MVN:-"/opt/apache/maven/bin/mvn"}
VERSION=${VERSION:-"$(./build-root/scripts/version rpm-version)"}

make test-doc

if [[ ${JOB_NAME} == *merge* ]]; then
  mkdir -p ${RESOURCES_DIR}
  mv -f ${DOC_DIR} ${RESOURCES_DIR}
  cd ${SITE_DIR}

  cat > pom.xml << EOF
  <project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>io.fd.vpp</groupId>
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
        <url>dav:${DOCS_REPO_URL}/${PROJECT_PATH}/${VERSION}</url>
      </site>
    </distributionManagement>
  </project>
EOF
  ${MVN} -B site:site site:deploy -gs "${GLOBAL_SETTINGS_FILE}" -s "${SETTINGS_FILE}" -T 4C
  cd -
fi
