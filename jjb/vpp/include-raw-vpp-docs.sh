#!/bin/bash
set -xe -o pipefail
[ "$DOCS_REPO_URL" ] || DOCS_REPO_URL="https://nexus.fd.io/content/sites/site/"
[ "$PROJECT_PATH" ] || PROJECT_PATH=io/fd/vpp
[ "$DOC_FILE" ] || DOC_FILE=vpp.docs.zip
[ "$DOC_DIR" ] || DOC_DIR=build-root/docs/html
if [ "${GERRIT_BRANCH}" == "stable/1609" ]; then
  VERSION=16.09
else
  echo "************************************"
  echo "* ${GERRIT_BRANCH} does not publish docs  *"
  echo "************************************"
  exit
fi
MVN="/opt/apache/maven/bin/mvn"

sudo apt-get install -y zip

make doxygen
cd ${DOC_DIR}
zip -r ${DOC_FILE} *
cat pom.xml << EOF
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>io.fd.vpp</groupId>
  <artifactId>docs</artifactId>
  <version>1.0.0</version>
  <packaging>pom</packaging>
  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-deploy-plugin</artifactId>
        <version>2.8.2</version>
        <configuration>
          <skip>true</skip>
        </configuration>
      </plugin>
      <plugin>
        <groupId>org.sonatype.plugins</groupId>
        <artifactId>maven-upload-plugin</artifactId>
        <version>0.0.1</version>
        <executions>
          <execution>
            <id>publish-site</id>
            <phase>deploy</phase>
            <goals>
              <goal>upload-file</goal>
            </goals>
            <configuration>
              <serverId>opendaylight-log-archives</serverId>
              <repositoryUrl>$DOCS_REPO_URL/content-compressed</repositoryUrl>
              <file>${DOC_FILE}</file>
              <repositoryPath>${PROJECT_PATH}/${VERSION}</repositoryPath>
            </configuration>
          </execution>
        </executions>
      </plugin>
    </plugins>
  </build>
</project>
EOF
${MVN} deploy -gs "${GLOBAL_SETTINGS_FILE}" -s "${SETTINGS_FILE}"
cd -

