#!/bin/bash
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
elif [ "${OS}" == "ubuntu1404" ]; then

    # Build the debs
    ./packaging/deb/trusty/debuild.sh

    # Find the files
    DEBS=$(find . -type f -iname '*.deb')
    for i in $DEBS
    do
        push_deb "$i"
    done
elif [ "${OS}" == "ubuntu1604" ]; then

    # Build the debs
    ./packaging/deb/xenial/debuild.sh

    # Find the files
    DEBS=$(find . -type f -iname '*.deb')
    for i in $DEBS
    do
        push_deb "$i"
    done
fi
