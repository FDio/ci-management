#!/bin/bash
set -xeu -o pipefail

# create HC .deb packages
if [ "${OS}" == "ubuntu1404" ]; then

    ./packaging/deb/trusty/debuild.sh
    cp ./packaging/deb/trusty/*.deb ./csit

elif [ "${OS}" == "ubuntu1604" ]; then

    ./packaging/deb/xenial/debuild.sh
    cp ./packaging/deb/xenial/*.deb ./csit
fi

cd csit
# execute csit bootstrap script if it exists
if [ ! -e bootstrap-hc2vpp-verify.sh ]
then
    echo 'ERROR: No bootstrap-hc2vpp-verify.sh found'
    exit 1
else
    # make sure that bootstrap.sh is executable
    chmod +x bootstrap-hc2vpp-verify.sh
    # run the script
    ./bootstrap-hc2vpp-verify.sh
fi

# vim: ts=4 ts=4 sts=4 et :