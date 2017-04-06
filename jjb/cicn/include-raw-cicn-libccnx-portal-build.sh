#!/bin/bash
# basic build script example
set -euxo pipefail
IFS=$'\n\t'

PACKAGE_NAME="LIBCCNX_PORTAL"
PACKAGE_DEPS="LIBCCNX_PORTAL_DEPS"
pushd libccnx-portal
build_package $PACKAGE_NAME $PACKAGE_DEPS
popd
