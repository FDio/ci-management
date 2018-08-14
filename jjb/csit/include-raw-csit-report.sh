#!/bin/bash

set -xe -o pipefail

[ "$DOCS_REPO_URL" ] || DOCS_REPO_URL="https://nexus.fd.io/content/sites/site"
[ "$PROJECT_PATH" ] || PROJECT_PATH=io/fd/csit
[ "$DOC_DIR" ] || DOC_DIR=resources/tools/presentation
[ "$BUILD_DIR" ] || BUILD_DIR=${DOC_DIR}/_build
[ "$SITE_DIR" ] || SITE_DIR=build-root/docs/deploy-site
[ "$RESOURCES_DIR" ] || RESOURCES_DIR=${SITE_DIR}/src/site/resources/report
[ "$MVN" ] || MVN="/opt/apache/maven/bin/mvn"

cd ${DOC_DIR}
chmod +x ./run_report.sh
./run_report.sh ${GERRIT_BRANCH}

retval=$?
if [ ${retval} -ne "0" ]; then
  echo "Report generation failed!"
exit ${retval}
fi

if [[ ${JOB_NAME} == *merge* ]]; then

  cd ${WORKSPACE}

  mkdir -p ${RESOURCES_DIR}
  mv -f ${BUILD_DIR}/* ${RESOURCES_DIR}
  cd ${SITE_DIR}

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
          <version>2.9</version>
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

  ${MVN} site:site site:deploy -B -gs "${GLOBAL_SETTINGS_FILE}" -s "${SETTINGS_FILE}" -T 4C

  cd -

fi
