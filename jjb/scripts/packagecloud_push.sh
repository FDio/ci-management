#!/bin/bash
# PCIO_CO is a Jenkins Global Environment variable

set -x

echo "STARTING PACKAGECLOUD PUSH"

sleep 10

if [ -f /usr/bin/zypper ]; then
    FACTER_OS="openSUSE"
else
    FACTER_OS=$(/usr/bin/facter operatingsystem)
fi

if [ -f ~/.packagecloud ]; then
    case "$FACTER_OS" in
      Ubuntu)
        FACTER_LSBNAME=$(/usr/bin/facter lsbdistcodename)
        DEBS=$(find . -type f -iname '*.deb')
        package_cloud push "${PCIO_CO}/${STREAM}/ubuntu/${FACTER_LSBNAME}/main/" ${DEBS}
      ;;
      CentOS)
        FACTER_OSMAJREL=$(/usr/bin/facter operatingsystemmajrelease)
        FACTER_ARCH=$(/usr/bin/facter architecture)
        RPMS=$(find . -type f -iregex '.*/.*\.\(s\)?rpm')
        package_cloud push "${PCIO_CO}/${STREAM}/el/${FACTER_OSMAJREL}/os/${FACTER_ARCH}/" ${RPMS}
      ;;
      openSUSE)
        # Use /etc/os-release on openSUSE to get $VERSION
        . /etc/os-release
        RPMS=$(find . -type f -iregex '.*/.*\.\(s\)?rpm')
        package_cloud push "${PCIO_CO}/${STREAM}/opensuse/${VERSION}/" ${RPMS}
      ;;
    esac
fi
