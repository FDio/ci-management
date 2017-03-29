#!/bin/bash

if [ "${OS}" == "ubuntu1404" ]; then
    DEBS=$(find . -type f -iname '*.deb')
    package_cloud push ${PCIO_CO}/${stream}/ubuntu/trusty/main ${DEBS}
elif [ "${OS}" == "ubuntu1604" ]; then
    DEBS=$(find . -type f -iname '*.deb')
    package_cloud push ${PCIO_CO}/${stream}/ubuntu/xenial/main ${DEBS}
elif [ "${OS}" == "centos7" ]; then
    # Find the files
    RPMS=$(find . -type f -iregex '.*/.*\.\(s\)?rpm')
    package_cloud push ${PCIO_CO}/${stream}/el/7/os/x86_64/ ${RPMS}
fi
