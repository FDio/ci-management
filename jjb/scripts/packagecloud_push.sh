#!/bin/bash

# PCIO_CO is a Jenkins Global Environment variable

FACTER_OS=$(/usr/bin/facter operatingsystem)
FACTER_OSVER=$(/usr/bin/facter operatingsystemrelease)
FACTER_LSBNAME=$(/usr/bin/facter lsbdistcodename)
FACTER_LSBMAJOR=$(/usr/bin/facter lsbmajdistrelease)
FACTER_ARCH=$(/usr/bin/facter architecture)
DEBS=$(find . -type f -iname '*.deb')
RPMS=$(find . -type f -iregex '.*/.*\.\(s\)?rpm')

case "$FACTER_OS" in
  Ubuntu)
    if [ "$FACTER_OSVER" == "14.04" ]
    then
      package_cloud push "${PCIO_CO}/${STREAM}/ubuntu/$FACTER_LSBNAME/main/" ${DEBS}
    elif [ "$FACTER_OSVER" == "16.04" ]
    then
      package_cloud push "${PCIO_CO}/$STREAM}/ubuntu/$FACTER_LSBNAME/main/" ${DEBS}
    fi
  ;;
  CentOS)
    if [ "$FACTER_OSVER" == "7" ]
    then
      package_cloud push "${PCIO_CO}/${STREAM}/el/$FACTER_LSBMAJOR/os/$FACTER_ARCH/" ${RPMS}
    fi
  ;;
esac
