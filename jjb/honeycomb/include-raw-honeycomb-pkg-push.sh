#!/bin/bash
set -xe -o pipefail

if [ -z "${MAVEN_SELECTOR}" ]; then
    echo "ERROR: No Maven install detected!"
    exit 1
fi

if [ "${OS}" == "centos7" ]; then

    # Build the rpms

    ./packaging/rpm/rpmbuild.sh

    # Find the files
    RPMS=$(find . -type f -iname '*.rpm')
    SRPMS=$(find . -type f -iname '*.srpm')
    SRCRPMS=$(find . -type f -name '*.src.rpm')
    for i in $RPMS $SRPMS $SRCRPMS
    do
        push_rpm "$i"
    done
fi
