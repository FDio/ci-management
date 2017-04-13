#!/bin/bash
# basic build script example
set -euxo pipefail
IFS=$'\n\t'

pushd libccnx-portal/scripts
bash build-package.sh
popd
