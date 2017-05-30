#!/bin/bash
set -x

# determine VPP Java API version used in maven build
if [ "${OS}" == "centos7" ]; then
    VERSION=`yum list installed vpp-api-java | grep vpp-api-java | awk '{ printf $2; }'`
    # write a file that will echo VPP dependencies
    echo -n 'echo' > vpp_dependencies
    echo " \"vpp = ${VERSION}, vpp-plugins = ${VERSION}\"" >> vpp_dependencies
    chmod +x vpp_dependencies
    # overwrite default dependencies file
    mv vpp_dependencies packaging/rpm/
else
    VERSION=`apt list --installed | grep vpp-api-java | awk '{ printf $2; }'`
    # write a file that will echo VPP dependencies
    echo -n 'echo' > vpp_dependencies
    echo " \"vpp (= ${VERSION}), vpp-plugins (= ${VERSION})\"" >> vpp_dependencies
    chmod +x vpp_dependencies
    # overwrite default dependencies file
    mv vpp_dependencies packaging/deb/common/
fi

if [ "${OS}" == "centos7" ]; then

    # Build the rpms
    ./packaging/rpm/rpmbuild.sh

    # Find the files
    RPMS=$(find . -type f -iname '*.rpm')
    SRPMS=$(find . -type f -iname '*.srpm')
    SRCRPMS=$(find . -type f -name '*.src.rpm')
    # publish hc2vpp packages
    for i in $RPMS $SRPMS $SRCRPMS
    do
        push_rpm "$i"
    done
elif [ "${OS}" == "ubuntu1604" ]; then

    # Build the debs
    ./packaging/deb/xenial/debuild.sh

    # Find the files
    DEBS=$(find . -type f -iname '*.deb')
    # publish hc2vpp packages
    for i in $DEBS
    do
        push_deb "$i"
    done
fi
