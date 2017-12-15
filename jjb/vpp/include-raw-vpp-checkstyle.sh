#!/bin/bash

OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')

if [ "$OS_ID" == "opensuse" ];then
	echo "openSUSE runs indent 2.2.10 which differs from other distros (2.2.11)"
	exit 0
fi

if [ -f build-root/scripts/checkstyle.sh ];then
    build-root/scripts/checkstyle.sh
else
    echo "Cannot find cat build-root/scripts/checkstyle.sh - skipping checkstyle"
fi
