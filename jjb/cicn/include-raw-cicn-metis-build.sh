#!/bin/bash
# basic build script example
set -euxo pipefail
IFS=$'\n\t'

PACKAGE_NAME="METIS"
PACKAGE_DEPS="METIS_DEPS"
pushd metis
build_package $PACKAGE_NAME $PACKAGE_DEPS
popd