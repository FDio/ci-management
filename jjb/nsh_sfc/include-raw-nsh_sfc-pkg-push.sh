#!/bin/bash
# basic build script example
set -e -o pipefail

if [ "${OS}" == "ubuntu1404" ]; then
    cd nsh-plugin/build/java/jvpp
    $MVN deploy \
        -gs "$GLOBAL_SETTINGS_FILE" -s "$SETTINGS_FILE"
    cd -
fi