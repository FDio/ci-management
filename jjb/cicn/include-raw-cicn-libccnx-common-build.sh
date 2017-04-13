#!/bin/bash
# basic build script example
set -euxo pipefail
IFS=$'\n\t'

pushd libccnx-common/scripts
bash build-package.sh
popd
