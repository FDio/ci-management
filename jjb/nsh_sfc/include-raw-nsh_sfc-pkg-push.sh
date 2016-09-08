#!/bin/bash
# basic build script example
set -e -o pipefail

cd nsh-plugin/build/java/jvpp
$MVN org.apache.maven.plugins:maven-deploy-plugin:deploy \
    -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
cd -
