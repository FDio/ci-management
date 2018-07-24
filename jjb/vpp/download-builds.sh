#!/usr/bin/env bash

set -exu -o pipefail

cd "$WORKSPACE"
rm -rf build-root build_parent build_new archive
wget -N --progress=dot:giga "https://jenkins.fd.io/sandbox/job/vpp-csit-verify-hw-perf-master-up/1/artifact/*zip*/archive.zip"
unzip archive.zip
mv archive/build_parent ./
mv archive/build_new ./
cp -r build_new build-root
# Create symlinks so that if job fails on robot test, results can be archived.
ln -s csit csit_new
