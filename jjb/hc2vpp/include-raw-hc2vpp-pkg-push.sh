#!/bin/bash
set -x

# determine Java API version used in maven build
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
    # install hc2vpp
    sudo rpm -i ${RPMS}

elif [ "${OS}" == "ubuntu1404" ]; then

    # Build the debs
    ./packaging/deb/trusty/debuild.sh
    # Find the files
    DEBS=$(find . -type f -iname '*.deb')
    # install hc2vpp
    sudo dpkg -i ${DEBS}

elif [ "${OS}" == "ubuntu1604" ]; then

    # Build the debs
    ./packaging/deb/xenial/debuild.sh
    # Find the files
    DEBS=$(find . -type f -iname '*.deb')
    # install hc2vpp
    sudo dpkg -i ${DEBS}

fi

# Run smoke test to verify VPP+HC2VPP compatibility
sudo service vpp start && sudo service honeycomb start
TIME_TAKEN=0
TIMEOUT=180
COMMAND_STATUS=0
until [ ${COMMAND_STATUS} -eq 0 ] || [ ${TIME_TAKEN} -eq ${TIMEOUT} ]; do
  curl -s -f -u admin:admin 127.0.0.1:8183/restconf/operational/ietf-interfaces:interfaces-state
  COMMAND_STATUS=`echo $?`
  sleep 10
  let TIME_TAKEN=TIME_TAKEN+10
done

if [ ${COMMAND_STATUS} -ne 0 ]; then
    echo "Smoke test failed after retrying for ${TIMEOUT} seconds. Package will not be published."
    exit
fi

# publish hc2vpp package
if [ "${OS}" == "centos7" ]; then

    for i in $RPMS $SRPMS $SRCRPMS
    do
        push_rpm "$i"
    done
else
    for i in $DEBS
    do
        push_deb "$i"
    done
fi
