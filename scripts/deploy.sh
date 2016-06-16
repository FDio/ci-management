#!/bin/bash

VERSION=16.06
JAR_VERSION="${VERSION}-SNAPSHOT"
RH_VERSION="${VERSION}-release.${ARCH}"

declare -A JAR_TAG=( [jvpp]=20160616.165833-38 [vppjapi]=20160616.165830-38 )

DEB_ARCH=amd64
RH_ARCH=x86_64

ARCH=${DEB_ARCH}

SRC_PFX=fd.io.stable.1606

for PKG in vpp-dbg vpp-lib vpp-dpdk-dkms vpp-dpdk-dev vpp-dev vpp
do
    for DEB_DIST in ubuntu.trusty.main ubuntu.xenial.main
    do
        SRC_REPO="${SRC_PFX}.${DEB_DIST}"
        DST_REPO=fd.io.${DEB_DIST}
        ARTIFACT_ID="${PKG}-${VERSION}"

        mkdir -p ${SRC_REPO}

        BASENAME="${ARTIFACT_ID}_${ARCH}.deb"
        wget -c -P ${SRC_REPO} "https://nexus.fd.io/content/repositories/${SRC_REPO}/io/fd/vpp/${PKG}/${VERSION}_${ARCH}/${BASENAME}"
        echo mvn org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
            -DgroupId=io.fd.vpp \
            -DartifactId="${ARTIFACT_ID}" \
            -Dversion="${VERSION}" \
            -DgeneratePom=true \
            -Dpackaging=deb \
            -DrepositoryId="${DST_REPO}" \
            -Durl="https://nexus.fd.io/content/repositories/${DST_REPO}" \
            -Dfile="${SRC_REPO}/${BASENAME}"
    done
done

ARCH=${RH_ARCH}

for PKG in vpp vpp-lib vpp-devel
do
    for RH_DIST in centos7
    do
        SRC_REPO="${SRC_PFX}.${RH_DIST}"
        DST_REPO="fd.io.${RH_DIST}"
        ARTIFACT_ID="${PKG}-${RH_VERSION}"
        mkdir -p ${SRC_REPO}

        BASENAME="${ARTIFACT_ID}.rpm"
        wget -c -P ${SRC_REPO} "https://nexus.fd.io/content/repositories/${SRC_REPO}/io/fd/vpp/${PKG}/${RH_VERSION}/${BASENAME}"
        echo mvn org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
            -DgroupId=io.fd.vpp \
            -DartifactId="${ARTIFACT_ID}" \
            -Dversion="${RH_VERSION}" \
            -DgeneratePom=true \
            -Dpackaging=rpm \
            -DrepositoryId="${DST_REPO}" \
            -Durl="https://nexus.fd.io/content/repositories/${DST_REPO}" \
            -Dfile="${SRC_REPO}/${BASENAME}"
    done
done

for PKG in jvpp vppjapi
do

    SRC_REPO=fd.io.snapshot
    DST_REPO=fd.io.release
    ARTIFACT_ID="${PKG}-${VERSION}"
    mkdir -p ${SRC_REPO}

    BASENAME="${ARTIFACT_ID}-${JAR_TAG[${PKG}]}.jar"
    wget -c -P ${SRC_REPO} "https://nexus.fd.io/content/repositories/${SRC_REPO}/io/fd/vpp/${PKG}/${JAR_VERSION}/${BASENAME}"
    echo mvn org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
        -DgroupId=io.fd.vpp \
        -DartifactId="${ARTIFACT_ID}" \
        -Dversion="${VERSION}" \
        -DgeneratePom=true \
        -Dpackaging=rpm \
        -DrepositoryId="${DST_REPO}" \
        -Durl="https://nexus.fd.io/content/repositories/${DST_REPO}" \
        -Dfile="${SRC_REPO}/${BASENAME}"

done

#https://nexus.fd.io/content/repositories/fd.io.snapshot/io/fd/vpp/jvpp/16.06-SNAPSHOT/jvpp-16.06-20160616.165833-38.jar
#https://nexus.fd.io/content/repositories/fd.io.snapshot/io/fd/vpp/vppjapi/16.06-SNAPSHOT/vppjapi-16.06-20160616.165830-38.jar

