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

echo "---> jjb/include-raw-deploy-archives.sh"

set +e  # Do not affect the build result if some part of archiving fails.

ARCHIVES_DIR="$JENKINS_HOSTNAME/$JOB_NAME/$BUILD_NUMBER"
[ "$LOGS_SERVER" ] || LOGS_SERVER="https://logs.fd.io"
[ "$LOGS_REPO_URL" ] || LOGS_REPO_URL="https://nexus.fd.io/service/local/repositories/logs"

echo "Build logs: <a href=\"$LOGS_SERVER/$SILO/$ARCHIVES_DIR\">$LOGS_SERVER/$SILO/$ARCHIVES_DIR</a>"

mkdir .archives
cd .archives/

cat > deploy-archives.xml <<EOF
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>logs</groupId>
  <artifactId>logs</artifactId>
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
              <serverId>logs</serverId>
              <repositoryUrl>$LOGS_REPO_URL/content-compressed</repositoryUrl>
              <file>archives.zip</file>
              <repositoryPath>$SILO</repositoryPath>
            </configuration>
          </execution>
        </executions>
      </plugin>
    </plugins>
  </build>
</project>
EOF

mkdir -p $ARCHIVES_DIR
mkdir -p $WORKSPACE/archives
if [ ! -z "${{ARCHIVE_ARTIFACTS}}" ]; then
    pushd $WORKSPACE
    shopt -s globstar  # Enable globstar to copy archives
    archive_artifacts=$(echo ${{ARCHIVE_ARTIFACTS}})
    for f in $archive_artifacts; do
        echo "Archiving $f"
        mkdir -p $WORKSPACE/archives/$(dirname $f)
        mv $f $WORKSPACE/archives/$f
    done
    shopt -u globstar  # Disable globstar once archives are copied
    popd
fi


# Ignore logging if archives doesn't exist
mv $WORKSPACE/archives/ $ARCHIVES_DIR > /dev/null 2>&1
touch $ARCHIVES_DIR/_build-details.txt
echo "build-url: ${{BUILD_URL}}" >> $ARCHIVES_DIR/_build-details.txt
env > $ARCHIVES_DIR/_build-enviroment-variables.txt

# capture system info
touch $ARCHIVES_DIR/_sys-info.txt
{{
    echo -e "uname -a:\n `uname -a` \n"
    echo -e "df -h:\n `df -h` \n"
    echo -e "free -m:\n `free -m` \n"
    echo -e "nproc:\n `nproc` \n"
    echo -e "lscpu:\n `lscpu` \n"
    echo -e "ip addr:\n  `/sbin/ip addr` \n"
}} 2>&1 | tee -a $ARCHIVES_DIR/_sys-info.txt

# Magic string used to trim console logs at the appropriate level during wget
echo "-----END_OF_BUILD-----"
wget -q --timeout=60 -O $ARCHIVES_DIR/console.log ${{BUILD_URL}}consoleText
wget -q --timeout=60 -O $ARCHIVES_DIR/console-timestamp.log ${{BUILD_URL}}/timestamps?time=HH:mm:ss\&appendLog
sed -i '/^-----END_OF_BUILD-----$/,$d' $ARCHIVES_DIR/console.log
sed -i '/^.*-----END_OF_BUILD-----$/,$d' $ARCHIVES_DIR/console-timestamp.log

gzip $ARCHIVES_DIR/*.txt $ARCHIVES_DIR/*.log
# find and gzip any 'text' files
find $ARCHIVES_DIR -type f -print0 \
                | xargs -0r file \
                | egrep -e ':.*text.*' \
                | cut -d: -f1 \
                | xargs -d'\n' -r gzip

zip -r archives.zip $JENKINS_HOSTNAME/
du -sh archives.zip
