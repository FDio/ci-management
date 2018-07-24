#!/usr/bin/env bash

set -exu -o pipefail

cd "$WORKSPACE"
git fetch https://gerrit.fd.io/r/csit "$CSIT_REF" && git checkout FETCH_HEAD
source "csit/resources/tools/jenkins/patch_vote/main.sh"
