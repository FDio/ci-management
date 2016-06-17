#!/bin/bash
set -xe -o pipefail

# Determine the path to maven
if [ -n "${MAVEN_SELECTOR}" ]
then
    MVN=${MVN:-"${HOME}/tools/hudson.tasks.Maven_MavenInstallation/${MAVEN_SELECTOR}/bin/mvn"}
else
    MVN="$(which mvn)"
fi

if [ -z "${MVN}" ]; then
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
