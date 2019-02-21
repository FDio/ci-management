#!/bin/bash

set -ex
# Download the latest VPP java API package
VERSION="RELEASE"
VERSION=`./jvpp-version`

# Figure out what system we are running on
if [[ -f /etc/lsb-release ]];then
    . /etc/lsb-release
elif [[ -f /etc/redhat-release ]];then
    sudo yum install -y redhat-lsb
    DISTRIB_ID=`lsb_release -si`
    DISTRIB_RELEASE=`lsb_release -sr`
    DISTRIB_CODENAME=`lsb_release -sc`
    DISTRIB_DESCRIPTION=`lsb_release -sd`
fi
echo "----- OS INFO -----"
echo DISTRIB_ID: ${DISTRIB_ID}
echo DISTRIB_RELEASE: ${DISTRIB_RELEASE}
echo DISTRIB_CODENAME: ${DISTRIB_CODENAME}
echo DISTRIB_DESCRIPTION: ${DISTRIB_DESCRIPTION}

echo "----- DOWNLOADING PACKAGES -----"
if ! [[ -z ${REPO_NAME} ]]; then
    REPO_URL="https://packagecloud.io/fdio/${STREAM}"
    echo "REPO_URL: ${REPO_URL}"
    if [[ "$DISTRIB_ID" == "Ubuntu" ]]; then
        if [[ -f /etc/apt/sources.list.d/99fd.io.list ]];then
            echo "Deleting: /etc/apt/sources.list.d/99fd.io.list"
            sudo rm /etc/apt/sources.list.d/99fd.io.list
        fi
        curl -s https://packagecloud.io/install/repositories/fdio/${STREAM}/script.deb.sh | sudo bash
        if [[ "${VERSION}" != 'RELEASE' ]]; then
            # download specific version if set
            echo VERSION: ${VERSION}
            apt-get download vpp-api-java=${VERSION} || true
        else
            # download latest version for specified stream
            apt-get download vpp-api-java || true
        fi

    elif [[ "$DISTRIB_ID" == "CentOS" ]]; then
        if [[ -f /etc/yum.repos.d/fdio-master.repo ]]; then
            echo "Deleting: /etc/yum.repos.d/fdio-master.repo"
            sudo rm /etc/yum.repos.d/fdio-master.repo
        fi
        curl -s https://packagecloud.io/install/repositories/fdio/${STREAM}/script.rpm.sh | sudo bash
        if [[ "${VERSION}" != 'RELEASE' ]]; then
            # download specific version if set
            echo VERSION: ${VERSION}
            sudo yum -y install --downloadonly --downloaddir=./ vpp-api-java-${VERSION} || true
        else
            # download latest version for specified stream
            sudo yum -y install --downloadonly --downloaddir=./ vpp-api-java || true
        fi
    fi
fi

# install vpp-api-java, this extracts jvpp .jar files into usr/share/java
if [[ "${OS}" == "centos7" ]]; then
    sudo rpm --nodeps --install vpp-api-java*
else
    sudo dpkg --ignore-depends=vpp,vpp-plugin-core --install vpp-api-java*
fi
sudo rm vpp-api-java*

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
    mvn install:install-file -Dfile=${item} -DgroupId=io.fd.jvpp -DartifactId=${artifactId} -Dversion=${version} -Dpackaging=jar -Dmaven.repo.local=/tmp/r -Dorg.ops4j.pax.url.mvn.localRepository=/tmp/r
done

cd ${current_dir}
