#!/bin/bash

# THIS BLOCK CAN BE REMOVED ONCE THE PATCH https://gerrit.fd.io/r/#/c/8280/ is merged
# BLOCK BEGIN
OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')

echo OS_ID: $OS_ID
echo OS_VERSION_ID: $OS_VERSION_ID

if [ "$OS_ID" == "opensuse" ]; then
	echo "##############################################################################"
	echo "# Removing the cloud repo added in some previous steps with the wrong command "
	sudo zypper rr openSUSE-Leap-Cloud-Tools
	echo "# Installing clang package"
	sudo zypper install -y libclang llvm-clang
	echo " # Installing NASM 2.13"
	sudo zypper install -y https://download.opensuse.org/tumbleweed/repo/oss/suse/x86_64/nasm-2.13.01-2.1.x86_64.rpm
	echo "Adding the correct Cloud Repo"
	sudo zypper --non-interactive --gpg-auto-import-keys --no-gpgcheck ar --refresh -n CloudRepo \
		http://download.opensuse.org/repositories/Cloud:/Tools/openSUSE_Leap_42.3/Cloud:Tools.repo
fi
# BLOCK END

if [ -f build-root/scripts/checkstyle.sh ];then
    build-root/scripts/checkstyle.sh
else
    echo "Cannot find cat build-root/scripts/checkstyle.sh - skipping checkstyle"
fi
