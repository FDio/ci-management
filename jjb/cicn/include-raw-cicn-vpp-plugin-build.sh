#!/bin/bash
# basic build script example
set -exuo pipefail
IFS=$'\n\t'

PACKAGE_NAME="VPP_PLUGIN"
PACKAGE_DEPS="VPP_PLUGIN_DEPS"

pushd cicn-plugin
build_package $PACKAGE_NAME $PACKAGE_DEPS
popd