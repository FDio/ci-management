#!/bin/bash
# basic build script example
set -euxo pipefail
IFS=$'\n\t'

pushd emu-radio/scripts
bash build-package.sh
popd
