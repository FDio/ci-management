#!/bin/bash
# basic build script example
set -euxo pipefail

pushd scripts
bash ./build-vpp-latest.sh
popd
