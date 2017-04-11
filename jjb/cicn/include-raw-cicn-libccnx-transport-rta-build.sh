#!/bin/bash
# basic build script example
set -euxo pipefail
IFS=$'\n\t'

pushd libccnx-transport-rta/scripts
bash build-package.sh
popd
