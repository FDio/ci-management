#!/bin/bash
# basic build script example
set -euo pipefail
IFS=$'\n\t'

source ./build-package.sh

PACKAGE_NAME="LIBCCNX_COMMON"
PACKAGE_DEPS="LIBCCNX_COMMON_DEPS"
cd libccnx-common
build_package $PACKAGE_NAME $PACKAGE_DEPS