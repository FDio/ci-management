#!/bin/bash
set -x

# In case of master branch, update vpp_dependencies file
# to match vpp-api-java and eliminate Java API mismatches (HC2VPP-102).
#
# In order to have control of package dependencies in the release artifacts (HC2VPP-282),
# the vpp_dependencies file is not modified in case of stable branch
# (after VPP API freeze, Java API mismatches occur very rarely).
if [[ "${STREAM}" == "master" ]]; then
    if [[ "${OS}" == "centos7" ]]; then
        # Determine VPP Java API version used in maven build
        JVPP_VERSION=`yum list installed vpp-api-java | grep vpp-api-java | awk '{ printf $2; }'`
        VERSION=`yum deplist vpp-api-java |grep vpp-lib |head -1 | awk '{ print $3}'`

        # Write a file that will echo VPP dependencies
        echo -n 'echo' > vpp_dependencies
        echo " \"vpp = ${VERSION}, vpp-plugins = ${VERSION}, vpp-api-java = ${JVPP_VERSION}\"" >> vpp_dependencies
        chmod +x vpp_dependencies

        # Overwrite default dependencies file
        mv vpp_dependencies packaging/rpm/
    else
        # Determine VPP Java API version used in maven build
        JVPP_VERSION=`apt list --installed | grep vpp-api-java | awk '{ printf $2; }'`
        # get vpp-api-java package dependencies
        JVPP_DEPS=`apt-cache show vpp-api-java=${JVPP_VERSION} |grep Depends: | sed "s/Depends: //"`
        # separate deps with newline, then find VPP dependency and filter out the version
        VERSION=`echo ${JVPP_DEPS}| sed "s/, /\\n/" |grep "vpp " | sed "s/).*//" |sed "s/.* //"`

        # Write a file that will echo VPP dependencies
        echo -n 'echo' > vpp_dependencies
        echo " \"vpp (= ${VERSION}), vpp-plugin-core (= ${VERSION}), vpp-api-java (= ${JVPP_VERSION})\"" >> vpp_dependencies
        chmod +x vpp_dependencies

        # Overwrite default dependencies file
        mv vpp_dependencies packaging/deb/common/
    fi
fi

# Build package
if [[ "${OS}" == "centos7" ]]; then

    # Build the rpms
    ./packaging/rpm/rpmbuild.sh

    # Find the files
    RPMS=$(find ./packaging/ -type f -iname '*.rpm')
    SRPMS=$(find ./packaging/ -type f -iname '*.srpm')
    SRCRPMS=$(find ./packaging/ -type f -name '*.src.rpm')

    # Publish hc2vpp packages
    for i in ${RPMS} ${SRPMS} ${SRCRPMS}
    do
        push_rpm "$i"
    done
elif [[ "${OS}" == "ubuntu1604" ]]; then

    # Build the debs
    ./packaging/deb/xenial/debuild.sh

    # Find the files
    DEBS=$(find ./packaging/ -type f -iname '*.deb')

    # Publish hc2vpp packages
    for i in ${DEBS}
    do
        push_deb "$i"
    done
elif [[ "${OS}" == "ubuntu1804" ]]; then

    # Build the debs
    ./packaging/deb/bionic/debuild.sh

    # Find the files
    DEBS=$(find ./packaging/ -type f -iname '*.deb')

    # Publish hc2vpp packages
    for i in ${DEBS}
    do
        push_deb "$i"
    done
fi
