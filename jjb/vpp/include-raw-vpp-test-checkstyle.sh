#!/bin/bash

OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')

if [ "$OS_ID" == "opensuse" ];then
	echo "openSUSE runs indent 2.2.10 which differs from other distros (2.2.11)"
	exit 0
fi

if grep '.PHONY: checkstyle' test/Makefile > /dev/null
then
	make test-checkstyle
else
	echo "Can't find checkstyle target in test/Makefile - skipping test checkstyle"
fi
