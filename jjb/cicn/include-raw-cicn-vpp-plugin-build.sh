#!/bin/bash
# basic build script example
set -euo pipefail
IFS=$'\n\t'

PACKAGE_NAME="VPP_PLUGIN"
PACKAGE_DEPS="VPP_PLUGIN_DEPS"

cd cicn-plugin

build_package $PACKAGE_NAME $PACKAGE_DEPS
