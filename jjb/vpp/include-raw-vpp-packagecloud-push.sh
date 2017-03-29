#!/bin/bash

STREAM='{$STREAM}'
FACTER_OS='{$FACTER_OS}'
FACTER_OSVER='{$FACTER_OSVER}'

case "$FACTER_OS" in
    Ubuntu)
        if [ "$FACTER_OSVER" == "14.04" ]
        then
            DEBS=$(find . -type f -iname '*.deb')
            package_cloud push '${PCIO_CO}/${STREAM}/ubuntu/trusty/main/' ${DEBS}
        elif [ "$FACTER_OSVER" == "16.04" ]
            DEBS=$(find . -type f -iname '*.deb')
            package_cloud push '${PCIO_CO}/${STREAM}/ubuntu/xenial/main/' ${DEBS}
        else
            echo "---> OS Release is not supported"
        fi
    ;;
    CentOS)
        if [ "$FACTER_OSVER" == "7" ]
        then
            RPMS=$(find . -type f -iregex '.*/.*\.\(s\)?rpm')
            package_cloud push '${PCIO_CO}/${STREAM}/el/7/os/x86_64/' ${RPMS}
        else
            echo "---> OS Release is not supported"
        fi
    ;;
esac 
