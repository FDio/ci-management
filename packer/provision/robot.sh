#!/bin/bash

# vim: ts=4 sw=4 sts=4 et tw=72 :

rh_systems() {
    # Assumes that python is already installed by basebuild

    # Install dependencies for robotframework and robotframework-sshlibrary
    yum install -y -q yum-utils unzip sshuttle nc libffi-devel openssl-devel

    # Install docker
    yum install -y docker supervisor bridge-utils
    systemctl enable docker

    # configure docker networking so that it does not conflict with LF
    # internal networks
    cat <<EOL > /etc/sysconfig/docker-network
# /etc/sysconfig/docker-network
DOCKER_NETWORK_OPTIONS='--bip=10.250.0.254/24'
EOL
    # configure docker daemon to listen on port 5555 enabling remote
    # managment
    sed -i -e "s#='--selinux-enabled'#='--selinux-enabled -H unix:///var/run/docker.sock -H tcp://0.0.0.0:5555'#g" /etc/sysconfig/docker

    # docker group doesn't get created by default for some reason
    groupadd docker

    # Actual installation of robot is done from an integration JJB script
}

ubuntu_systems() {
    # Assumes that python is already installed by basebuild

    # Install dependencies for robotframework and robotframework-sshlibrary
    apt install -y unzip sshuttle netcat libffi-dev libssl-dev

    # Install docker
    apt install -y docker.io

    # Actual installation of robot is done from an integration JJB script
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
