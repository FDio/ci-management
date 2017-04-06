#!/bin/bash
# basic build script example
set -euxo pipefail
IFS=$'\n\t'

PACKAGE_NAME="LONGBOW"
PACKAGE_DEPS="LONGBOW_DEPS"
pushd longbow
build_package $PACKAGE_NAME $PACKAGE_DEPS
popd