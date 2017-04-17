# packagecloud.io promote script
# This script will promote packages from the packagecloud.io staging repository
# to the packagecloud.io release repository

# package_cloud promote username/myrepo/[distro/version] packagename.ext username/destination_repo
#
# Add staging repo variable = to username/myrepo/[distro/version]
#  example:  https://packagecloud.io/fdio/staging
#  need to create a packagecloud staging repository
#
# Add release repo variable = to username/destination_repo
#  example:  https://packagecloud.io/fdio/release
#  need to create a packagecloud release repository
#
# How to push multiple packages at the same time
#   RPMS=$(find . -type f -iregex '.*/.*\.\(s\)?rpm')
#   DEBS=$(find . -type f -iname '*.deb') - need to be able to specify the version
#   example:  17.01-release.x86_64 and 17.01-release_amd64

#!bin/bash

# Possible variables to be used
FACTER_OS=$(/usr/bin/facter operatingsystem)
FACTER_LSBNAME=$(/usr/bin/facter lsbdistcodename)
STAGE_REPO="$(${PCIO_CO}/staging/)"
REL_REPO="$(${PCIO_CO}/release/)"
FACTER_OSMAJREL=$(/usr/bin/facter operatingsystemmajrelease)

# The package_cloud promote command requires the full filename of the package
# Currently testing CentOS only

# Use the repository metadata to query for the release packages?

for package in $(package_list.txt); do
    echo package_cloud promote $STAGE_REPO/el/${FACTER_OSMAJREL}/ $package $REL_REPO/el/${FACTER_OSMAJREL}/
done
