#!/bin/bash
echo "---> jjb/scripts/cicn/docs-libparc.sh"
set -xe -o pipefail

update_cmake_repo() {
    cat /etc/resolv.conf
    echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
    cat /etc/resolv.conf

    CMAKE_INSTALL_SCRIPT_URL="https://cmake.org/files/v3.8/cmake-3.8.0-Linux-x86_64.sh"
    CMAKE_INSTALL_SCRIPT="/tmp/install_cmake.sh"
    curl ${CMAKE_INSTALL_SCRIPT_URL} > ${CMAKE_INSTALL_SCRIPT}

    sudo mkdir -p /opt/cmake
    sudo bash ${CMAKE_INSTALL_SCRIPT} --skip-license --prefix=/opt/cmake
    export PATH=/opt/cmake/bin:$PATH
}

cd libparc

[ "$DOC_DIR" ] || DOC_DIR="build/documentation/generated-documentation/html"
[ "$SITE_DIR" ] || SITE_DIR="build/documentation/deploy-site/"
[ "$RESOURCES_DIR" ] || RESOURCES_DIR=${SITE_DIR}/src/site/resources

update_cmake_repo
mkdir -p build
pushd build
cmake -DDOC_ONLY=ON ..
make documentation
popd

if [[ ${JOB_NAME} == *merge* ]]; then
  mkdir -p $(dirname ${RESOURCES_DIR})
  mv -f ${DOC_DIR} ${RESOURCES_DIR}
  cd ${SITE_DIR}
  find . -type f '(' -name '*.md5' -o -name '*.dot' -o -name '*.map' ')' -delete
  cd -
fi
