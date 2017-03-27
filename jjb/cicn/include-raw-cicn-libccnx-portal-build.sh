#!/bin/bash
# basic build script example
set -euo pipefail
IFS=$'\n\t'

source ./build-package.sh

PACKAGE_NAME="LIBCCNX_PORTAL"
PACKAGE_DEPS="LIBCCNX_PORTAL_DEPS"
cd libccnx-portal
build_package $PACKAGE_NAME $PACKAGE_DEPS