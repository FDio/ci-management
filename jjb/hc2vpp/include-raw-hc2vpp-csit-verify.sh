#!/bin/bash
set -xeu -o pipefail

# Figure out what system we are running on
if [[ -f /etc/lsb-release ]];then
    . /etc/lsb-release
elif [[ -f /etc/redhat-release ]];then
    sudo yum install -y redhat-lsb
    DISTRIB_ID=`lsb_release -si`
    DISTRIB_RELEASE=`lsb_release -sr`
    DISTRIB_CODENAME=`lsb_release -sc`
    DISTRIB_DESCRIPTION=`lsb_release -sd`
fi
echo "----- OS INFO -----"
echo DISTRIB_ID: ${DISTRIB_ID}
echo DISTRIB_RELEASE: ${DISTRIB_RELEASE}
echo DISTRIB_CODENAME: ${DISTRIB_CODENAME}
echo DISTRIB_DESCRIPTION: ${DISTRIB_DESCRIPTION}

if [[ "$DISTRIB_ID" != "Ubuntu" ]]; then
    echo 'ERROR: Only Ubuntu is supported currently.'
    exit 2
fi

# create HC .deb packages
./packaging/deb/${DISTRIB_CODENAME}/debuild.sh
cp ./packaging/deb/${DISTRIB_CODENAME}/*.deb ${WORKSPACE}/csit

cd ${WORKSPACE}/csit
# execute csit bootstrap script if it exists
if [[ ! -e bootstrap-hc2vpp-verify.sh ]]
then
    echo 'ERROR: No bootstrap-hc2vpp-verify.sh found'
    exit 1
else
    # make sure that bootstrap.sh is executable
    chmod +x bootstrap-hc2vpp-verify.sh
    # run the script
    ./bootstrap-hc2vpp-verify.sh ${OS}
fi

# vim: ts=4 ts=4 sts=4 et :