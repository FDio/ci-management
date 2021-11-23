#!/bin/bash
echo "---> jjb/scripts/cicn/build-viper.sh"
set -euxo pipefail
IFS=$'\n\t'

pushd scripts
bash build-package.sh
popd
