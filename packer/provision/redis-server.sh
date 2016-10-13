#!/bin/bash

# vim: ts=4 sw=4 sts=4 et tw=72 :

rh_systems() {
    echo "---> Installing IUS repo and Redis"
    # make sure that IUS is installed
    yum install -y https://centos7.iuscommunity.org/ius-release.rpm
    # now install redis 3.2.x
    yum install -y redis32u
    systemctl enable redis
}

ubuntu_systems() {
    echo "---> Installing Redis"
    # Install redis-server
    apt install -y redis-server
}

all_systems() {
    echo 'No common distribution configuration to perform'
}

echo "---> Detecting OS"
ORIGIN=$(facter operatingsystem | tr '[:upper:]' '[:lower:]')

case "${ORIGIN}" in
    fedora|centos|redhat)
        echo "---> RH type system detected"
        rh_systems
    ;;
    ubuntu)
        echo "---> Ubuntu system detected"
        ubuntu_systems
    ;;
    *)
        echo "---> Unknown operating system"
    ;;
esac

# execute steps for all systems
all_systems
