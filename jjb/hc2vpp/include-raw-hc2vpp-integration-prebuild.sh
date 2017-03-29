#!/bin/bash

set -ex

STREAM=$1
OS=$2

# Download the latest VPP java API package and its dependencies
URL="https://nexus.fd.io/service/local/artifact/maven/content"
VERSION="RELEASE"
GROUP="io.fd.vpp"
ARTIFACTS="vpp vpp-lib vpp-api-java"

if [ "${OS}" == "ubuntu1404" ]; then
    OS="ubuntu.trusty.main"
    PACKAGE="deb deb.md5"
    CLASS="deb"
elif [ "${OS}" == "ubuntu1604" ]; then
    OS="ubuntu.xenial.main"
    PACKAGE="deb deb.md5"
    CLASS="deb"
elif [ "${OS}" == "centos7" ]; then
    OS="centos7"
    PACKAGE="rpm rpm.md5"
    CLASS="rpm"
fi

REPO="fd.io.${STREAM}.${OS}"

for ART in ${ARTIFACTS}; do
    for PAC in ${PACKAGE}; do
        curl "${URL}?r=${REPO}&g=${GROUP}&a=${ART}&p=${PAC}&v=${VERSION}&c=${CLASS}" -O -J || exit
    done
done

for FILE in *.deb; do
    echo " "${FILE} >> ${FILE}.md5
done
for FILE in *.rpm; do
    echo " "${FILE} >> ${FILE}.md5
done
for MD5FILE in *.md5; do
    md5sum -c ${MD5FILE} || exit
done

# install vpp-api-java and dependencies, this extracts .jar files into usr/share/java
sudo dpkg -i vpp*
rm vpp*

# install jvpp jars into maven repo, so that maven picks them up when building hc2vpp
current_dir=`pwd`
cd /usr/share/java

for item in jvpp*.jar; do
    # Example filename: jvpp-registry-17.01-20161206.125556-1.jar
    # ArtifactId = jvpp-registry
    # Version = 17.01
    basefile=$(basename -s .jar "$item")
    artifactId=$(echo "$basefile" | cut -d '-' -f 1-2)
    version=$(echo "$basefile" | cut -d '-' -f 3)
    mvn install:install-file -Dfile=${item} -DgroupId=io.fd.vpp -DartifactId=${artifactId} -Dversion=${version} -Dpackaging=jar -Dmaven.repo.local=/tmp/r -Dorg.ops4j.pax.url.mvn.localRepository=/tmp/r
done

cd current_dir
