#!/bin/bash
echo "---> jjb/scripts/cicn/build-libparc.sh"
set -euxo pipefail
IFS=$'\n\t'

pushd libparc/scripts
bash build-package.sh
popd
