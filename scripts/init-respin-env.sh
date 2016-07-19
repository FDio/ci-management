#!/bin/bash

# Copyright 2016 The Linux Foundation

set -e

vagrant_version=1.8.1
ruby_version=2.1.5
ruby_patch=https://gist.github.com/mislav/055441129184a1512bb5.txt
rbenv_git=https://github.com/rbenv/rbenv.git

CPPROJECT=fdio

PVENAME="${CPPROJECT}-openstack"
PVE_ROOT="${HOME}/src/python-virtual"
PVE_PATH="${PVE_ROOT}/${PVENAME}"
PVERC=${PVE_PATH}/bin/activate
PVE_BINDIR=$(dirname $PVERC)

LOCAL_LIB="${HOME}/src/local-lib"
LL_LIBDIR="${LOCAL_LIB}/lib"

RH_ARCH64=x86_64
RH_ARCH32=i686
DEB_ARCH64=amd64
DEB_ARCH32=i386
LV_IMG_DIR=/var/lib/libvirt/images/
SRC_TIMESTAMP=""
DST_TIMESTAMP=""

function init_virtualenv ()
{
    test -d ${PVE_BINDIR} && return 0

    if [ -f /etc/debian_version ]
    then
        sudo apt-get -y -qq install virtualenvwrapper python-virtualenv libpython-dev
    elif [ -f /etc/redhat-release ]
    then
        sudo yum -y install python-virtualenv
    fi

    mkdir -p ${PVE_PATH}
    virtualenv ${PVE_PATH}

    echo "Please copy all OS_* variables from https://secure.vexxhost.com/console/#/account/credentials to the end of ${PVERC}"
    echo "Press enter when finished"
    read
}

function init_local_lib ()
{
    test -d ${LL_LIBDIR} && return 0

    echo "local lib init incomplete"
}

function init_javascript ()
{
    which js && which jq && return 0

    if [ -f /etc/debian_version ]
    then
        sudo apt-get -y -qq install nodejs jq
    elif [ -f /etc/redhat-release ]
    then
        sudo yum -y install nodejs jq
    fi
}

function init_vagrant ()
{
    which vagrant && return 0

    vagrant_pkg_name=vagrant_${vagrant_version}_x86_64.deb
    vagrant_pkg=https://releases.hashicorp.com/vagrant/${vagrant_version}/${vagrant_pkg_name}

    wget -t 10 -q -c /tmp/${vagrant_pkg}
    sudo dpkg -i /vagrant/${vagrant_pkg_name}
}

function init_rbenv ()
{
    which rbenv && return 0

    # clone rbenv
    test -d ~/.rbenv/.git || git clone ${rbenv_git} ~/.rbenv

    # clone ruby-build
    mkdir -p ~/.rbenv/plugins
    test -d ~/.rbenv/plugins/ruby-build/.git || git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

    # build ruby-build
    cd ~/.rbenv && src/configure && make -C src

    # Add rbenv to bashrc
    grep HOME/.rbenv/bin ~/.bashrc || echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc

    # Add rbenv to current environment
    export PATH="$HOME/.rbenv/bin:$PATH"
}

function init_ruby ()
{
    rbenv versions | grep -q ${ruby_version} && return 0

    # Install ruby build deps
    sudo apt-get build-dep ruby
    #sudo apt-get -y install \
    #     autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev \
    #     zlib1g-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev

    # Build ruby
    curl -fsSL ${ruby_patch} | rbenv install --patch ${ruby_version}
}

function select_ruby ()
{
    # Select ruby ${ruby_version} from rbenv
    rbenv local ${1}
    rbenv global ${1}
}

function install_vagrant_plugins ()
{
    plugs=$(vagrant plugin list)
    for plugin in vagrant-openstack-provider vagrant-cachier vagrant-mutate
    do
        echo ${plugs} | grep -q ${plugin} && continue
        vagrant plugin install ${plugin}
    done
}

function import_vagrant_box ()
{
    # Skip if already done
    if [ -f ${HOME}/.vagrant.d/boxes/dummy/0/openstack/Vagrantfile ]; then return ; fi

    # Add dummy box
    vagrant box add dummy https://github.com/huit/vagrant-openstack/blob/master/dummy.box

    cp ${CI_MGMT}/vagrant/examples/box/dummy/Vagrantfile ~/.vagrant.d/boxes/dummy/0/openstack/
}


init_virtualenv
init_rbenv
init_ruby
select_ruby ${ruby_version}
init_virtualenv
init_vagrant
install_vagrant_plugins
import_vagrant_box
init_local_lib
init_javascript
