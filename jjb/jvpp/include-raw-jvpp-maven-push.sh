#!/bin/bash
set -xe -o pipefail
echo "*******************************************************************"
echo "* STARTING PUSH OF JVPP PACKAGES TO REPOS"
echo "* NOTHING THAT HAPPENS BELOW THIS POINT IS RELATED TO BUILD FAILURE"
echo "*******************************************************************"

[ "$MVN" ] || MVN="/opt/apache/maven/bin/mvn"
GROUP_ID="io.fd.${PROJECT}"
BASEURL="${NEXUSPROXY}/content/repositories/fd.io."
BASEREPOID='fdio-'

if [ "${OS}" == "ubuntu1604" ]; then
    # Find the files
    JARS=$(find ./java -type f -iname '*.jar')
    DEBS=$(find ./build-root/packages/ -type f -iname '*.deb')
    for i in $JARS
    do
        push_jar "$i"
    done

    for i in $DEBS
    do
        push_deb "$i"
    done
elif [ "${OS}" == "ubuntu1804" ]; then
    # Find the files
    JARS=$(find ./java -type f -iname '*.jar')
    DEBS=$(find ./build-root/packages/ -type f -iname '*.deb')
    for i in $JARS
    do
        push_jar "$i"
    done

    for i in $DEBS
    do
        push_deb "$i"
    done
elif [ "${OS}" == "centos7" ]; then
    # Find the files
    RPMS=$(find ./build-root/packages/ -type f -iname '*.rpm')
    SRPMS=$(find ./build-root/packages/ -type f -iname '*.srpm')
    SRCRPMS=$(find ./build-root/packages/ -type f -name '*.src.rpm')
    for i in $RPMS $SRPMS $SRCRPMS
    do
        push_rpm "$i"
    done
fi
# vim: ts=4 sw=4 sts=4 et ft=sh :
