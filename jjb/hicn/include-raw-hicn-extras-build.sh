#!/bin/bash
# basic build script example
set -euxo pipefail

pushd scripts
bash ./build-extras.sh
popd
