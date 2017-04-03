#!/bin/bash
# basic build script example
set -euo pipefail
IFS=$'\n\t'

apt_get=`which apt-get`

PACKAGE_NAME="VIPER"
VIPER_DEPS_UBUNTU="zlib1g-dev git-core build-essential libxml2-dev libcurl4-openssl-dev \
                   qt57base qt57svg qt57charts-no-lgpl qt57multimedia libqtav-dev libicnet \
                   libavcodec-dev libavformat-dev libswscale-dev  libavresample-dev libqml-module-qtav \
                   qt57quickcontrols qt57quickcontrols2 libxml2-dev"

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
    update_qt_repo $DISTRIB_CODENAME
    echo $BUILD_TOOLS $VIPER_DEPS_UBUNTU | xargs sudo ${apt_get} install -y --allow-unauthenticated
else
    echo "This package is currently supported only for ubuntu. Exiting.."
    exit -1
fi

# Create links

sudo ln -sf /usr/include/x86_64-linux-gnu/qt5/QtAV                                /opt/qt57/include/QtAV
sudo ln -sf /usr/lib/x86_64-linux-gnu/qt5/mkspecs/features/av.prf                 /opt/qt57/mkspecs/features/av.prf
sudo ln -sf /usr/lib/x86_64-linux-gnu/qt5/mkspecs/features/avwidgets.prf          /opt/qt57/mkspecs/features/avwidgets.prf
sudo ln -sf /usr/lib/x86_64-linux-gnu/qt5/mkspecs/modules/qt_lib_avwidgets.pri    /opt/qt57/mkspecs/modules/qt_lib_avwidgets.pri
sudo ln -sf /usr/lib/x86_64-linux-gnu/qt5/mkspecs/modules/qt_lib_av.pri           /opt/qt57/mkspecs/modules/qt_lib_av.pri
sudo ln -sf /usr/lib/x86_64-linux-gnu/libQtAV.prl                                 /opt/qt57/lib/libQtAV.prl
sudo ln -sf /usr/lib/x86_64-linux-gnu/libQtAVWidgets.prl                          /opt/qt57/lib/libQtAVWidgets.prl
sudo ln -sf /usr/lib/x86_64-linux-gnu/libQtAVWidgets.so                           /opt/qt57/lib/libQt5AVWidgets.so
sudo ln -sf /usr/lib/x86_64-linux-gnu/libQt5AV.so                                 /opt/qt57/lib/libQt5AV.so
sudo ln -sf /usr/lib/x86_64-linux-gnu/libQtAV.so                                  /opt/qt57/lib/libQtAV.so
sudo ln -sf /usr/lib/x86_64-linux-gnu/libQt5AVWidgets.so                          /opt/qt57/lib/libQtAVWidgets.so

# Compile libdash


build() {
    mkdir -p build
    cd build
    rm -rf *
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DRPM_PACKAGE=$RPM -DDEB_PACKAGE=$DEB -DDISTRIBUTION=$DISTRIB_CODENAME -DARCHITECTURE=$ARCHITECTURE ..
    make
}

# Build libdash
pushd libdash
build
make package
sudo make install
popd

# Build viper
build
make package
