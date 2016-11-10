#!/bin/bash

if [ -f /usr/bin/yum ]; then
  sudo yum -y remove facter puppet hiera rdo-release
  sudo yum -y install libxml2-devel libxslt-devel ruby-devel zlib-devel
  sudo yum -y groupinstall "Development Tools"
  # Uninstall python-requests from pip, since we install it in
  # system-config/install_puppet.sh
  #sudo pip uninstall requests -y || true
elif [ -f /usr/bin/apt-get ]; then
  sudo apt-get remove -y --purge facter puppet puppet-common hiera
  sudo apt-get update
  sudo apt-get install -y libxml2-dev libxslt-dev zlib1g-dev
  # /etc/default/puppet is not purged when removing Puppet
  # but need to be dropped if we want to re-install puppet-agent on Xenial
  sudo rm -rf /etc/default/puppet
fi
