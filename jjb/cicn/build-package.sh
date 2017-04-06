#!/bin/bash
# basic build script example
set -euxo pipefail
IFS=$'\n\t'

apt_get=`which apt-get`

# Parameters:
# $1 = Distribution [trusty / CentOS]
#
update_cmake_repo() {

    DISTRIBUTION=$1

    if [ "$DISTRIBUTION" == "trusty" ]; then
        sudo ${apt_get} install -y --allow-unauthenticated software-properties-common
        sudo add-apt-repository --yes ppa:george-edison55/cmake-3.x
    elif [ "$DISTRIBUTION" == "CentOS" ]; then
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
    fi
}

# Parameters:
# $1 = Distribution codename
#
update_qt_repo() {
    DISTRIBUTION_CODENAME=$1

    if [ "$DISTRIBUTION_CODENAME" != "trusty" ] && [ "$DISTRIBUTION_CODENAME" != "xenial" ]; then
        echo "No valid distribution specified when calling 'update_qt_repo'. Exiting.."
        exit -1
    fi

    sudo ${apt_get} install -y --allow-unauthenticated software-properties-common
    sudo add-apt-repository --yes ppa:beineri/opt-qt571-$DISTRIBUTION_CODENAME

    wget -q -O - http://archive.getdeb.net/getdeb-archive.key | sudo apt-key add -
    sudo sh -c "echo 'deb http://archive.getdeb.net/ubuntu $DISTRIBUTION_CODENAME-getdeb apps' >> /etc/apt/sources.list.d/getdeb.list"

    sudo ${apt_get} update
}

# Parameters:
# $1 = Distribution id
# $2 = Distribution codename
#
update_fdio_repo() {
    DISTRIB_ID=$1
    DISTRIB_CODENAME=$2

    if ! [ -z ${REPO_NAME} ]; then
        REPO_CICN_URL="${NEXUSPROXY}/content/repositories/fd.io.${REPO_NAME}"
        REPO_VPP_URL=""

        if [ "$DISTRIB_ID" == "Ubuntu" ]; then

            if [ "$DISTRIB_CODENAME" == "xenial" ]; then
                REPO_VPP_URL="${NEXUSPROXY}/content/repositories/fd.io.stable.1701.ubuntu.xenial.main/"
            elif [ "$DISTRIB_CODENAME" == "trusty" ]; then
                REPO_VPP_URL="${NEXUSPROXY}/content/repositories/fd.io.stable.1701.ubuntu.trusty.main/"
            else
                echo "Distribution $DISTRIB_CODENAME is not supported"
                exit -1
            fi

            echo "deb ${REPO_VPP_URL} ./" | sudo tee /etc/apt/sources.list.d/99fd.io.list
            echo "deb ${REPO_CICN_URL} ./" | sudo tee /etc/apt/sources.list.d/99fd.io.master.list

        elif [ "$DISTRIB_ID" == "CentOS" ]; then
            REPO_VPP_URL="${NEXUSPROXY}/content/repositories/fd.io.centos7/"
                    sudo cat << EOF > fdio-master.repo
[fdio-master]
name=fd.io master branch latest merge
baseurl=${REPO_URL}
enabled=1
gpgcheck=0
EOF
            sudo mv fdio-master.repo /etc/yum.repos.d/fdio-master.repo
        else
            echo "Distribution $DISTRIB_CODENAME is not supported"
        fi
    else
        exit -1
    fi

}

setup() {

    DISTRIB_ID=$1
    DISTRIB_CODENAME=$2

    if [ "$DISTRIB_ID" == "Ubuntu" ]; then
        if [ "$DISTRIB_CODENAME" == "trusty" ]; then
            update_cmake_repo $DISTRIB_CODENAME
        fi

        update_fdio_repo $DISTRIB_ID $DISTRIB_CODENAME

        sudo ${apt_get} update || true

    elif [ "$DISTRIB_ID" == "CentOS" ]; then
        update_cmake_repo $DISTRIB_ID
        update_fdio_repo $DISTRIB_ID $DISTRIB_CODENAME
    fi
}

build_package() {

    ARCHITECTURE=`uname -m`

    # Figure out what system we are running on
    if [ -f /etc/lsb-release ];then

        BUILD_TOOLS="build-essential cmake"
        LIBSSL_LIBEVENT="libevent-dev libssl-dev"
        LONGBOW_DEPS=""
        LIBPARC_DEPS="longbow $LIBSSL_LIBEVENT"
        LIBCCNX_COMMON_DEPS="$LIBPARC_DEPS libparc"
        LIBCCNX_TRANSPORT_RTA_DEPS="$LIBCCNX_COMMON_DEPS libccnx-common"
        LIBCCNX_PORTAL_DEPS="$LIBCCNX_TRANSPORT_RTA_DEPS libccnx-transport-rta"
        LIBICNET_DEPS="$LIBCCNX_PORTAL_DEPS libboost-system-dev"
        METIS_DEPS="$LIBCCNX_TRANSPORT_RTA_DEPS libccnx-transport-rta"
        HTTP_SERVER_DEPS="$LIBICNET_DEPS libicnet libboost-regex-dev libboost-filesystem-dev"
        VPP_PLUGIN_DEPS="vpp-dev vpp-dpdk-dev"

        . /etc/lsb-release
        DEB=ON
        RPM=OFF

        if [ "$ARCHITECTURE" == "x86_64" ]; then
            ARCHITECTURE="amd64"
        fi

    elif [ -f /etc/redhat-release ];then

        BUILD_TOOLS_GROUP="'Development Tools'"
        BUILD_TOOLS_SINGLE="cmake"
        LIBSSL_LIBEVENT="libevent-devel openssl-devel"
        LONGBOW_DEPS=""
        LIBPARC_DEPS="longbow $LIBSSL_LIBEVENT"
        LIBCCNX_COMMON_DEPS="$LIBPARC_DEPS libparc"
        LIBCCNX_TRANSPORT_RTA_DEPS="$LIBCCNX_COMMON_DEPS libccnx-common"
        LIBCCNX_PORTAL_DEPS="$LIBCCNX_TRANSPORT_RTA_DEPS libccnx-transport-rta"
        LIBICNET_DEPS="$LIBCCNX_PORTAL_DEPS boost-devel"
        METIS_DEPS="$LIBCCNX_TRANSPORT_RTA_DEPS libccnx-transport-rta"
        HTTP_SERVER_DEPS="$LIBICNET_DEPS libicnet boost-devel"

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
        echo $BUILD_TOOLS ${!PACKAGE_DEPS} | xargs sudo ${apt_get} install -y --allow-unauthenticated
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

    # Make the package
    mkdir -p build && pushd build

    rm -rf *
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DRPM_PACKAGE=$RPM -DDEB_PACKAGE=$DEB -DDISTRIBUTION=$DISTRIB_CODENAME -DARCHITECTURE=$ARCHITECTURE ..
    make package

    popd

    echo "*******************************************************************"
    echo "* $PACKAGE_NAME BUILD SUCCESSFULLY COMPLETED"
    echo "*******************************************************************"

    exit 0
}
