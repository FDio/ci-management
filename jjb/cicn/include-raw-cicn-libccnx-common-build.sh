#!/bin/bash
# basic build script example
set -euxo pipefail
IFS=$'\n\t'

PACKAGE_NAME="LIBCCNX_COMMON"
PACKAGE_DEPS="LIBCCNX_COMMON_DEPS"
pushd libccnx-common
build_package $PACKAGE_NAME $PACKAGE_DEPS
popd
