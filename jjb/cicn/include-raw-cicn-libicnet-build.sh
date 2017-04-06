#!/bin/bash
# basic build script example
set -euxo pipefail
IFS=$'\n\t'

PACKAGE_NAME="LIBICNET"
PACKAGE_DEPS="LIBICNET_DEPS"
build_package $PACKAGE_NAME $PACKAGE_DEPS
