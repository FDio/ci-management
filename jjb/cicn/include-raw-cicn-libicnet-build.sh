#!/bin/bash
# basic build script example
set -euo pipefail
IFS=$'\n\t'

source ./build-package.sh

PACKAGE_NAME="LIBICNET"
PACKAGE_DEPS="LIBICNET_DEPS"
build_package $PACKAGE_NAME $PACKAGE_DEPS