#!/bin/bash
# basic build script example
set -euxo pipefail
IFS=$'\n\t'

apt_get=`which apt-get`

PACKAGE_NAME="RADIO_EMULATOR"
RADIO_EMULATOR_DEPS_UBUNTU="pkg-config libboost-all-dev libsqlite3-dev libopenmpi-dev libxml2-dev libwebsocketpp-dev"

BUILD_TOOLS="build-essential cmake"

ARCHITECTURE=`uname -m`

# Figure out what system we are running on
if [ -f /etc/lsb-release ];then

    . /etc/lsb-release
    DEB=ON
    RPM=OFF

    if [ "$ARCHITECTURE" == "x86_64" ]; then
        ARCHITECTURE="amd64"
    fi

elif [ -f /etc/redhat-release ];then

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

# Install deps

if [ $DISTRIB_ID == "Ubuntu" ]; then
    echo $BUILD_TOOLS $RADIO_EMULATOR_DEPS_UBUNTU | xargs sudo ${apt_get} install -y --allow-unauthenticated || true
else
    echo "This package is currently supported only for ubuntu. Exiting.."
    exit -1
fi

# Parameters
# $1 = WIFI / LTE
#
build() {
    PARAM=$1
    mkdir -p build
    cd build
    ls | grep -v *.deb | xargs rm -rf || true
    echo $PARAM | xargs cmake -DCMAKE_INSTALL_PREFIX=/usr -DRPM_PACKAGE=$RPM -DDEB_PACKAGE=$DEB -DDISTRIBUTION=$DISTRIB_CODENAME -DARCHITECTURE=$ARCHITECTURE ..
    make
}

# Install libns3

pushd emu-radio/ns3-packages
sudo dpkg -i *.deb || true
sudo apt-get -f install -y --allow-unauthenticated || true
popd

# Build wifi-emualtor
pushd emu-radio
build "-DWIFI=ON -DLTE=OFF"
make package
popd

# Build lte-emualtor
pushd emu-radio
build "-DLTE=ON -DWIFI=OFF"
make package
popd