#!/bin/bash

set -e

# fetch and install vagrant package
vagrant_version=1.8.1
vagrant_pkg_name=vagrant_${vagrant_version}_x86_64.deb
vagrant_pkg=https://releases.hashicorp.com/vagrant/${vagrant_version}/${vagrant_pkg_name}
wget -c $vagrant_pkg
sudo dpkg -i $vagrant_pkg_name

# clone rbenv
test -d ~/.rbenv/.git || git clone https://github.com/rbenv/rbenv.git ~/.rbenv

# clone ruby-build
mkdir -p ~/.rbenv/plugins
test -d ~/.rbenv/plugins/ruby-build/.git || git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

# build ruby-build
cd ~/.rbenv && src/configure && make -C src

# Add rbenv to bashrc
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile

# Add rbenv to current environment
export PATH="$HOME/.rbenv/bin:$PATH"

# Install ruby build deps
sudo apt-get build-dep ruby2.3
#sudo apt-get -y install \
#     autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev \
#     zlib1g-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev

# Build ruby 2.1.5
curl -fsSL https://gist.github.com/mislav/055441129184a1512bb5.txt | rbenv install --patch 2.1.5

# Select ruby 2.1.5 from rbenv
rbenv local 2.1.5
rbenv global 2.1.5

# Add dummy box
vagrant box add dummy https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box
cp ${CIADM_DIR}/vagrant/examples/box/dummy/Vagrantfile ~/.vagrant.d/boxes/dummy/0/openstack/
