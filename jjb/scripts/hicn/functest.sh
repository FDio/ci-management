#!/bin/bash
# basic build script example
set -euxo pipefail

echo "---> jjb/scripts/hicn/functest.sh"

pushd scripts
bash ./functional-tests.sh
popd
