#!/bin/bash
# basic build script example
set -euxo pipefail

echo "---> jjb/scripts/hicn/build-extras.sh"

pushd scripts
bash ./build-extras.sh
popd
