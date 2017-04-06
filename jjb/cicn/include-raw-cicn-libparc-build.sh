#!/bin/bash
# basic build script example
set -euxo pipefail
IFS=$'\n\t'

PACKAGE_NAME="LIBPARC"
PACKAGE_DEPS="LIBPARC_DEPS"
pushd libparc
build_package $PACKAGE_NAME $PACKAGE_DEPS
popd
