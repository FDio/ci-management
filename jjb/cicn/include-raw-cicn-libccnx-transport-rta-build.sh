#!/bin/bash
# basic build script example
set -euxo pipefail
IFS=$'\n\t'

PACKAGE_NAME="LIBCCNX_TRANSPORT_RTA"
PACKAGE_DEPS="LIBCCNX_TRANSPORT_RTA_DEPS"
pushd libccnx-transport-rta
build_package $PACKAGE_NAME $PACKAGE_DEPS
popd
