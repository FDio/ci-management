#!/bin/bash
set -euxo pipefail

echo "---> jjb/scripts/hicn/sonar.sh"

pushd scripts
bash ./build-sonar.sh
popd
