#!/bin/bash

if [ -f /usr/bin/yum ]; then
  sudo yum -y install libxml2-devel libxslt-devel ruby-devel zlib-devel
elif [ -f /usr/bin/apt-get ]; then
  sudo apt-get update
  sudo apt-get install -y libxml2-dev libxslt-dev zlib1g-dev
fi
