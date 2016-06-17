#!/bin/bash

# Copyright 2015,2016 The Linux Foundation
#           2015,2016 Cisco Systems

set -xe -o pipefail

if [ -z "${MAVEN_SELECTOR}" ]; then
    echo "ERROR: No Maven install detected!"
    exit 1
fi

if [ "${OS}" == "ubuntu1404" ]; then
    # Find the files
    JARS=$(find . -type f -iname '*.jar')
    DEBS=$(find . -type f -iname '*.deb')
    for i in $JARS
    do
        push_jar "$i"
    done

    for i in $DEBS
    do
        push_deb "$i"
    done
elif [ "${OS}" == "ubuntu1604" ]; then
    DEBS=$(find . -type f -iname '*.deb')
    for i in $DEBS
    do
        push_deb "$i"
    done
elif [ "${OS}" == "centos7" ]; then
    # Find the files
    RPMS=$(find . -type f -iname '*.rpm')
    SRPMS=$(find . -type f -iname '*.srpm')
    SRCRPMS=$(find . -type f -name '*.src.rpm')
    for i in $RPMS $SRPMS $SRCRPMS
    do
        push_rpm "$i"
    done
fi
# vim: ts=4 sw=4 sts=4 et ft=sh :
