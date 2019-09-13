#!/bin/bash

set -xe -o pipefail

[ "${DOCS_REPO_URL}" ] || DOCS_REPO_URL="https://nexus.fd.io/content/sites/site"
[ "${PROJECT_PATH}" ] || PROJECT_PATH="io/fd/csit"
[ "${DOC_DIR}" ] || DOC_DIR="resources/tools/presentation"
[ "${BUILD_DIR}" ] || BUILD_DIR="${DOC_DIR}/_build"
[ "${SECONDARY_BUILD_DIR}" ] || SECONDARY_BUILD_DIR="${DOC_DIR}_new/_build"
[ "${SITE_DIR}" ] || SITE_DIR="build-root/docs/deploy-site"
[ "${RESOURCES_DIR}" ] || RESOURCES_DIR="${SITE_DIR}/src/site/resources/trending"
[ "${STATIC_VPP_DIR}" ] || STATIC_VPP_DIR="${RESOURCES_DIR}/_static/vpp"
[ "${MVN}" ] || MVN="/opt/apache/maven/bin/mvn"

# Create a text file with email body in case the build fails:
cd "${WORKSPACE}"
mkdir -p "${STATIC_VPP_DIR}"
EMAIL_BODY="ERROR: The build number ${BUILD_NUMBER} of the job ${JOB_NAME} failed. For more information see: ${BUILD_URL}"
echo "${EMAIL_BODY}" > "${STATIC_VPP_DIR}/trending-failed-tests.txt"

cd "${DOC_DIR}"
chmod +x ./run_cpta.sh
STATUS=$(./run_cpta.sh | tail -1)

cd "${WORKSPACE}"

mkdir -p "${RESOURCES_DIR}"
mv -f ${BUILD_DIR}/* "${RESOURCES_DIR}"
if [ -d "${SECONDARY_BUILD_DIR}" ]; then
    mkdir -p "${SECONDARY_RESOURCES_DIR}"
    mv -f "${SECONDARY_BUILD_DIR}"/* "${SECONDARY_RESOURCES_DIR}"
fi
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

${MVN} site:site site:deploy -gs "${GLOBAL_SETTINGS_FILE}" -s "${SETTINGS_FILE}" -T 4C

cd -

if [ "${STATUS}" == "PASS" ]; then
    exit 0
else
    exit 1
fi
