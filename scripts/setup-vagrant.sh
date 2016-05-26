#!/bin/bash

set -e

vagrant_version=1.8.1
vagrant_pkg_name=vagrant_${vagrant_version}_x86_64.deb
vagrant_pkg=https://releases.hashicorp.com/vagrant/${vagrant_version}/${vagrant_pkg_name}
wget -c $vagrant_pkg
sudo dpkg -i $vagrant_pkg_name

test -d ~/.rbenv/.git || git clone https://github.com/rbenv/rbenv.git ~/.rbenv
mkdir -p ~/.rbenv/plugins
test -d ~/.rbenv/plugins/ruby-build/.git || git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

cd ~/.rbenv && src/configure && make -C src

echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
export PATH="$HOME/.rbenv/bin:$PATH"

sudo apt-get -y install autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev

curl -fsSL https://gist.github.com/mislav/055441129184a1512bb5.txt | rbenv install --patch 2.1.5

rbenv local 2.1.5
rbenv global 2.1.5

vagrant box add hashicorp/precise64
vagrant mutate --input-provider virtualbox  hashicorp/precise64 libvirt
