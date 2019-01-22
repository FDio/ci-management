#!/bin/bash
# basic build script example
set -euxo pipefail

pushd scripts
bash ./build-packages.sh
popd
