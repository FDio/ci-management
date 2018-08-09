#!/usr/bin/env bash

set -exuo pipefail

cd "${WORKSPACE}"
git clone https://gerrit.fd.io/r/csit --depth 1 --single-branch --no-checkout
pushd "csit"
# TODO: Is there a way for "git clone" to fetch "${CSIT_REF}" instead of a branch?
git fetch https://gerrit.fd.io/r/csit "${CSIT_REF}"
git checkout FETCH_HEAD
popd
source "${WORKSPACE}/csit/resources/libraries/bash/jenkins/perpatch_main.sh"
