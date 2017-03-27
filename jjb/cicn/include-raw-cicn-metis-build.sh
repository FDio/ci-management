#!/bin/bash
# basic build script example
set -euo pipefail
IFS=$'\n\t'

source ./build-package.sh

PACKAGE_NAME="METIS"
PACKAGE_DEPS="METIS_DEPS"
cd longbow
build_package $PACKAGE_NAME $PACKAGE_DEPS