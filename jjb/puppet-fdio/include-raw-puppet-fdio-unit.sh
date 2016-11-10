#!/bin/bash
set -e -o pipefail
# do nothing but print the current slave hostname
hostname

echo "cat /etc/bootstrap.sha"
if [ -f /etc/bootstrap.sha ];then
    cat /etc/bootstrap.sha
else
    echo "Cannot find /etc/bootstrap.sha"
fi

echo "cat /etc/bootstrap-functions.sha"
if [ -f /etc/bootstrap-functions.sha ];then
    cat /etc/bootstrap-functions.sha
else
    echo "Cannot find /etc/bootstrap-functions.sha"
fi

echo "sha1sum of this script: ${0}"
sha1sum $0

mkdir .bundled_gems
export GEM_HOME=`pwd`/.bundled_gems
gem install bundler --no-rdoc --no-ri --verbose
$GEM_HOME/bin/bundle install --retry 3
$GEM_HOME/bin/bundle exec rake syntax
$GEM_HOME/bin/bundle exec rake lint
$GEM_HOME/bin/bundle exec rake spec
$GEM_HOME/bin/bundle exec rake acceptance

echo "*******************************************************************"
echo "* rpm_dpdk BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
