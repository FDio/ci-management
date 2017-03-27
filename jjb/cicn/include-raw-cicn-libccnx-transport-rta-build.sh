#!/bin/bash
# basic build script example
set -euo pipefail
IFS=$'\n\t'

source ./build-package.sh

LIBCCNX_TRANSPORT_RTA="LIBCCNX_TRANSPORT_RTA"
LIBCCNX_TRANSPORT_RTA_DEPS="LIBCCNX_TRANSPORT_RTA_DEPS"
cd libccnx-transport-rta
build_package $PACKAGE_NAME $PACKAGE_DEPS