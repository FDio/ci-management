#!/bin/bash
# basic build script example
set -euxo pipefail

echo "---> jjb/scripts/hicn/build.sh"

pushd scripts
bash ./build-packages.sh
popd
