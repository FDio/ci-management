#!/bin/bash
# basic build script example
set -euo pipefail
IFS=$'\n\t'

PACKAGE_NAME="LIBCCNX_COMMON"
PACKAGE_DEPS="LIBCCNX_COMMON_DEPS"
cd libccnx-common
build_package $PACKAGE_NAME $PACKAGE_DEPS
