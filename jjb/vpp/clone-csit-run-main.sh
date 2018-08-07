#!/usr/bin/env bash

set -exu -o pipefail

cd "$WORKSPACE"
git clone https://gerrit.fd.io/r/csit --depth 1 --single-branch --no-checkout
cd "csit"
# TODO: Is there a way for "git clone" to fetch "$CSIT_REF" instead of a branch?
git fetch https://gerrit.fd.io/r/csit "$CSIT_REF"
git checkout FETCH_HEAD
cd "$WORKSPACE"
source "csit/resources/libraries/bash/jenkins/perpatch_main.sh"
