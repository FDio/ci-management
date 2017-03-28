#!/bin/bash
# basic build script example
set -euo pipefail
IFS=$'\n\t'

source ./build-package.sh

PACKAGE_NAME="LIBCCNX_TRANSPORT_RTA"
PACKAGE_DEPS="LIBCCNX_TRANSPORT_RTA_DEPS"
cd libccnx-transport-rta
build_package $PACKAGE_NAME $PACKAGE_DEPS