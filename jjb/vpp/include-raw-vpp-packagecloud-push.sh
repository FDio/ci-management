#!/bin/bash

if [ "${OS}" == "ubuntu1404" ]; then
    DEBS=$(find . -type f -iname '*.deb')
    for i in $DEBS
    do
        package_cloud push fdio/test "$i"
    done
elif [ "${OS}" == "ubuntu1604" ]; then
    DEBS=$(find . -type f -iname '*.deb')
    for i in $DEBS
    do
        package_cloud push fdio/test "$i"
    done
elif [ "${OS}" == "centos7" ]; then
    # Find the files
    RPMS=$(find . -type f -iname '*.rpm')
    SRPMS=$(find . -type f -iname '*.srpm')
    SRCRPMS=$(find . -type f -name '*.src.rpm')
    for i in $RPMS $SRPMS $SRCRPMS
    do
        package_cloud push fdio/test "$i"
    done
fi