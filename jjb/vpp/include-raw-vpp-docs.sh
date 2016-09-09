#!/bin/bash
set -xe -o pipefail
[ "$DOCS_REPO_URL" ] || DOCS_REPO_URL="https://nexus.fd.io/service/local/repositories/site"
[ "$PROJECT_PATH" ] || PROJECT_PATH=io/fd/vpp
[ "$DOC_FILE" ] || DOC_FILE=vpp.docs.zip
[ "$DOC_DIR" ] || DOC_DIR=build-root/docs/html
[ "$SITE_DIR" ] || SITE_DIR=build-root/docs/deploy-site/src/site
[ "$RESOURCES_DIR" ] || RESOURCES_DIR=${SITE_DIR}/src/site/resources
[ "$MVN" ] || MVN="/opt/apache/maven/bin/mvn"

if [ "${GERRIT_BRANCH}" == "stable/1609" ]; then
  VERSION=16.09
else
  echo "************************************"
  echo "* ${GERRIT_BRANCH} does not publish docs  *"
  echo "************************************"
  exit
fi

mkdir -p $(dirname ${RESOURCES_DIR})
mv -f ${DOC_DIR} ${RESOURCES_DIR}

make doxygen
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
         <version>2.9</version>
      </extension>
    </extensions>
  </build>
  <distributionManagement>
    <site>
      <id>fdio-site</id>
      <url>dav:${DOCS_REPO_URL}/site/${PROJECT_PATH}/${VERSION}</url>
    </site>
  </distributionManagement>
</project>
EOF
${MVN} site:deploy -gs "${GLOBAL_SETTINGS_FILE}" -s "${SETTINGS_FILE}"
cd -
