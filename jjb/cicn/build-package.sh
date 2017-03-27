#!/bin/bash
# basic build script example
set -euo pipefail
IFS=$'\n\t'

update_cmake_repo_trusty() {
    sudo apt-get install -y --allow-unauthenticated software-properties-common
    sudo add-apt-repository --yes ppa:george-edison55/cmake-3.x
}

update_cmake_repo_centos() {
    sudo cat << EOF > cmake.repo
[cmake-repo]
name=Repo for cmake3
baseurl=http://mirror.ghettoforge.org/distributions/gf/el/7/plus/x86_64/
enabled=1
gpgcheck=0
EOF
    sudo cat << EOF > jsoncpp.repo
[jsoncp-repo]
name=Repo for jsoncpp
baseurl=http://dl.fedoraproject.org/pub/epel/7/x86_64/
enabled=1
gpgcheck=0
EOF
    sudo mv cmake.repo /etc/yum.repos.d/cmake.repo
    sudo mv jsoncpp.repo /etc/yum.repos.d/jsoncpp.repo
}

setup() {

    DISTRIB_ID=$1
    DISTRIB_CODENAME=$2

    if ! [ -z ${REPO_NAME} ]; then
        REPO_URL="${NEXUSPROXY}/content/repositories/fd.io.${REPO_NAME}"
        echo "REPO_URL: ${REPO_URL}"
    else
        exit -1
    fi

    if [ $DISTRIB_ID == "Ubuntu" ]; then
        if [ "$DISTRIB_CODENAME" == "trusty" ]; then
            update_cmake_repo_trusty
        fi

        echo "deb ${REPO_URL} ./" | sudo tee /etc/apt/sources.list.d/99fd.io.list

        sudo apt-get update
    elif [ "$DISTRIB_ID" == "CentOS" ]; then
        update_cmake_repo_centos
        sudo cat << EOF > fdio-master.repo
[fdio-master]
name=fd.io master branch latest merge
baseurl=${REPO_URL}
enabled=1
gpgcheck=0
EOF
        sudo mv fdio-master.repo /etc/yum.repos.d/fdio-master.repo
    fi
}

build_package() {

    ARCHITECTURE=`uname -m`

    # Figure out what system we are running on
    if [ -f /etc/lsb-release ];then
        . /etc/lsb-release
        source ./ubuntu-dependencies
        DEB=ON
        RPM=OFF

        if [ "$ARCHITECTURE" == "x86_64" ]; then
            ARCHITECTURE="amd64"
        fi

    elif [ -f /etc/redhat-release ];then
        source ./centos-dependencies
        sudo yum install -y redhat-lsb
        DISTRIB_ID=`lsb_release -si`
        DISTRIB_RELEASE=`lsb_release -sr`
        DISTRIB_CODENAME=`lsb_release -sc`
        DISTRIB_DESCRIPTION=`lsb_release -sd`

        DEB=OFF
        RPM=ON
    else
        echo "ERROR: System configuration not recognized. Build failed"
        exit -1
    fi

    echo ARCHITECTURE: $ARCHITECTURE
    echo DISTRIB_ID: $DISTRIB_ID
    echo DISTRIB_RELEASE: $DISTRIB_RELEASE
    echo DISTRIB_CODENAME: $DISTRIB_CODENAME
    echo DISTRIB_DESCRIPTION: $DISTRIB_DESCRIPTION

    setup $DISTRIB_ID $DISTRIB_CODENAME

    if [ $DISTRIB_ID == "Ubuntu" ]; then
        echo $BUILD_TOOLS ${!PACKAGE_DEPS} | xargs sudo apt-get install -y --allow-unauthenticated
    elif [ $DISTRIB_ID == "CentOS" ]; then
        echo $BUILD_TOOLS_GROUP | xargs sudo yum groupinstall -y --nogpgcheck || true
        echo $BUILD_TOOLS_SINGLE | xargs sudo yum install -y --nogpgcheck || true
        echo ${!PACKAGE_DEPS} | xargs sudo yum install -y --nogpgcheck || true
    fi

    # do nothing but print the current slave hostname
    hostname

    # Install package dependencies

    export CCACHE_DIR=/tmp/ccache
    if [ -d $CCACHE_DIR ];then
        echo $CCACHE_DIR exists
        du -sk $CCACHE_DIR
    else
        echo $CCACHE_DIR does not exist.  This must be a new slave.
    fi

    echo "cat /etc/bootstrap.sha"
    if [ -f /etc/bootstrap.sha ];then
        cat /etc/bootstrap.sha
    else
        echo "Cannot find cat /etc/bootstrap.sha"
    fi

    echo "cat /etc/bootstrap-functions.sha"
    if [ -f /etc/bootstrap-functions.sha ];then
        cat /etc/bootstrap-functions.sha
    else
        echo "Cannot find cat /etc/bootstrap-functions.sha"
    fi

    echo "sha1sum of this script: ${0}"
    sha1sum $0

    # Make the package
    mkdir -p build && pushd build

    rm -rf *
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DRPM_PACKAGE=$RPM -DDEB_PACKAGE=$DEB -DDISTRIBUTION=$DISTRIB_CODENAME -DARCHITECTURE=$ARCHITECTURE ..
    make package

    echo "*******************************************************************"
    echo "* $PACKAGE_NAME BUILD SUCCESSFULLY COMPLETED"
    echo "*******************************************************************"

    exit 0
}