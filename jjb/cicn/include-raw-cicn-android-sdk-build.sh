#!/bin/bash
# basic build script example
set -euxo pipefail
IFS=$'\n\t'

pushd scripts
bash build-apk.sh
popd
