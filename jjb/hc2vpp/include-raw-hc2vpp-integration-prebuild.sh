#!/bin/bash

set -ex

# Download the latest VPP java API package
URL="https://nexus.fd.io/service/local/artifact/maven/content"
VERSION="RELEASE"
GROUP="io.fd.vpp"
ARTIFACTS="vpp-api-java"

VERSION=`./vpp-version`
if [ "${VERSION}" != 'RELEASE' ]; then
    if [ "${OS}" == "centos7" ]; then
        VERSION="${VERSION}.x86_64"
    else
        VERSION="${VERSION}_amd64"
    fi
fi

if [ "${OS}" == "ubuntu1604" ]; then
    OS_PART="ubuntu.xenial.main"
    PACKAGE="deb deb.md5"
    CLASS="deb"
elif [ "${OS}" == "centos7" ]; then
    OS_PART="centos7"
    PACKAGE="rpm rpm.md5"
    CLASS=""
fi

if [ "${STREAM}" == "master" ]; then
    STREAM_PART="master"
else
    STREAM_PART="stable.${STREAM}"
fi

REPO="fd.io.${STREAM_PART}.${OS_PART}"

for ART in ${ARTIFACTS}; do
    for PAC in ${PACKAGE}; do
        curl "${URL}?r=${REPO}&g=${GROUP}&a=${ART}&p=${PAC}&v=${VERSION}&c=${CLASS}" -O -J || exit
    done
done

# verify downloaded package
if [ "${OS}" == "centos7" ]; then
    FILES=*.rpm
else
    FILES=*.deb
fi

for FILE in ${FILES}; do
    echo " "${FILE} >> ${FILE}.md5
done
for MD5FILE in *.md5; do
    md5sum -c ${MD5FILE} || exit
    rm ${MD5FILE}
done

# install vpp-api-java, this extracts jvpp .jar files into usr/share/java
if [ "${OS}" == "centos7" ]; then
    sudo rpm --nodeps --install vpp-api-java*
else
    sudo dpkg --ignore-depends=vpp --install vpp-api-java*
fi
rm vpp-api-java*

# install jvpp jars into maven repo, so that maven picks them up when building hc2vpp
version=`./jvpp/version`

current_dir=`pwd`
cd /usr/share/java

for item in jvpp*.jar; do
    # Example filename: jvpp-registry-17.01-20161206.125556-1.jar
    # ArtifactId = jvpp-registry
    # Version = 17.01
    basefile=$(basename -s .jar "$item")
    artifactId=$(echo "$basefile" | cut -d '-' -f 1-2)
    mvn install:install-file -Dfile=${item} -DgroupId=io.fd.vpp -DartifactId=${artifactId} -Dversion=${version} -Dpackaging=jar -Dmaven.repo.local=/tmp/r -Dorg.ops4j.pax.url.mvn.localRepository=/tmp/r
done

cd ${current_dir}
