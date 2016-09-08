#!/bin/bash
# basic build script example
set -e -o pipefail
if [ "${OS}" == "ubuntu1404" ]; then
    export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
    export JAVAC=${JAVA_HOME}/bin/javac
    export PATH=${JAVA_HOME}/bin/:${PATH}
    cd nsh-plugin/build/java/jvpp
    $MVN deploy \
        -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
    cd -
fi