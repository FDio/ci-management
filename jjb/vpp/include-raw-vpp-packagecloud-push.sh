#!/bin/bash

if [ "${OS}" == "ubuntu1404" ]; then
    DEBS=$(find . -type f -iname '*.deb')
    package_cloud push fdio/test/ubuntu/trusty/main ${DEBS}
elif [ "${OS}" == "ubuntu1604" ]; then
    DEBS=$(find . -type f -iname '*.deb')
    package_cloud push fdio/test/ubuntu/xenial/main ${DEBS}
elif [ "${OS}" == "centos7" ]; then
    # Find the files
    RPMS=$(find . -type f -iname '*.rpm')
    SRPMS=$(find . -type f -iname '*.srpm')
    SRCRPMS=$(find . -type f -name '*.src.rpm')
    package_cloud push fdio/test/el/7/os/x86_64/ ${RPMS} ${SRPMS} ${SRCRPMS}
fi