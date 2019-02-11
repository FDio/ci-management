#!/bin/bash
set -x

# In case of master branch, update vpp_dependencies file
# to match vpp-api-java and eliminate Java API mismatches (HC2VPP-102).
#
# In order to have control of package dependencies in the release artifacts (HC2VPP-282),
# the vpp_dependencies file is not modified in case of stable branch
# (after VPP API freeze, Java API mismatches occur very rarely).
if [ "${STREAM}" == "master" ]; then
    if [ "${OS}" == "centos7" ]; then
        # Determine VPP Java API version used in maven build
        VERSION=`yum list installed vpp-api-java | grep vpp-api-java | awk '{ printf $2; }'`

        # Write a file that will echo VPP dependencies
        echo -n 'echo' > vpp_dependencies
        echo " \"vpp = ${VERSION}, vpp-plugins = ${VERSION}\"" >> vpp_dependencies
        chmod +x vpp_dependencies

        # Overwrite default dependencies file
        mv vpp_dependencies packaging/rpm/
    else
        # Determine VPP Java API version used in maven build
        VERSION=`apt list --installed | grep vpp-api-java | awk '{ printf $2; }'`

        # Write a file that will echo VPP dependencies
        echo -n 'echo' > vpp_dependencies
        echo " \"vpp (= ${VERSION}), vpp-plugin-core (= ${VERSION})\"" >> vpp_dependencies
        chmod +x vpp_dependencies

        # Overwrite default dependencies file
        mv vpp_dependencies packaging/deb/common/
    fi
fi

# Build package
if [ "${OS}" == "centos7" ]; then

    # Build the rpms
    ./packaging/rpm/rpmbuild.sh

    # Find the files
    RPMS=$(find . -type f -iname '*.rpm')
    SRPMS=$(find . -type f -iname '*.srpm')
    SRCRPMS=$(find . -type f -name '*.src.rpm')

    # Publish hc2vpp packages
    for i in $RPMS $SRPMS $SRCRPMS
    do
        push_rpm "$i"
    done
elif [ "${OS}" == "ubuntu1604" ]; then

    # Build the debs
    ./packaging/deb/xenial/debuild.sh

    # Find the files
    DEBS=$(find . -type f -iname '*.deb')

    # Publish hc2vpp packages
    for i in $DEBS
    do
        push_deb "$i"
    done
fi
