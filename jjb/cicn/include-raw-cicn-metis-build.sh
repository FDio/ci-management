#!/bin/bash
# basic build script example
set -euo pipefail
IFS=$'\n\t'

PACKAGE_NAME="METIS"
PACKAGE_DEPS="METIS_DEPS"
cd metis
build_package $PACKAGE_NAME $PACKAGE_DEPS
