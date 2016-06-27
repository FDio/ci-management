#!/bin/bash

set -xe -o pipefail

echo "*******************************************************************"
echo "* STARTING PUSH OF DEB-DPDK PACKAGES TO REPOS"
echo "* NOTHING THAT HAPPENS BELOW THIS POINT IS RELATED TO BUILD FAILURE"
echo "*******************************************************************"

# Determine the path to maven
if [ -z "${MAVEN_SELECTOR}" ]; then
    echo "ERROR: No Maven install detected!"
    exit 1
fi

MVN="${HOME}/tools/hudson.tasks.Maven_MavenInstallation/${MAVEN_SELECTOR}/bin/mvn"
GROUP_ID=""
BASEURL="${NEXUSPROXY}/content/repositories/debuntu"

# Find the files
DEBS=$(find . -type f -iname '*.deb'
              -o -iname '*.dsc'
              -o -iname '*.orig.tar.*'
              -o -iname '*.changes'
              -o -iname '*.build')

for i in $DEBS
do
    # TODO: verify that .orig.tar.* does not exist on repo, if it does, skip
    push_deb "$i"
done

echo "*******************************************************************"
echo "* PUSH OF DEB-DPDK PACKAGES COMPLETE"
echo "*******************************************************************"

# vim: ts=4 sw=4 sts=4 et ft=sh :
