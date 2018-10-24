#!/bin/bash
# @License EPL-1.0 <http://spdx.org/licenses/EPL-1.0>
##############################################################################
# Copyright (c) 2016 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

case "$(facter operatingsystem)" in
  Ubuntu)
    # make sure that the ca-certs are properly updated
    /usr/sbin/update-ca-certificates

    # attach to the fd.io.dev apt repo
#    echo 'deb http://nexus.fd.io/content/repositories/fd.io.dev/ ./' >> /etc/apt/sources.list

    # Configure Ubuntu mirror
    perl -pi -e 'unless(m{fd\.io}){ s{://[^/]+/}{://ca.archive.ubuntu.com/} }' /etc/apt/sources.list
    ;;
  *)
    # Do nothing on other distros for now
    ;;
esac

IPADDR=$(facter ipaddress)
HOSTNAME=$(facter hostname)
FQDN=$(facter fqdn)

echo "${IPADDR} ${HOSTNAME} ${FQDN}" >> /etc/hosts

#Increase limits
cat <<EOF > /etc/security/limits.d/jenkins.conf
jenkins         soft    nofile          16000
jenkins         hard    nofile          16000
EOF

cat <<EOJENKINS_SUDO >/etc/sudoers.d/89-jenkins-user-defaults
Defaults:jenkins !requiretty
jenkins     ALL = NOPASSWD: ALL
EOJENKINS_SUDO

cat <<EOSSH >> /etc/ssh/ssh_config
Host *
  ServerAliveInterval 60

# we don't want to do SSH host key checking on spin-up systems
# Don't use CIDR since SSH won't parse it
# 10.30.48.0/23
Host 10.30.48.* 10.30.49.*
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
EOSSH

cat <<EOKNOWN >  /etc/ssh/ssh_known_hosts
[gerrit.fd.io]:29418,[52.10.107.188]:29418 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCjr1oez076EFMo5n25lAJ2zhftLAHIkTmwTdjwR82xA8sqQbN0FMz4znZyO7o2jlewlw/OqnVAwEIvEto6tqoj1zu8bHS1Vwq4toKkk3SLzRdn8NeTL3K92IkEHhBfB7MGtDFnbKxGmC/MmcP7sUb3MUY9EyInP1ZBVDT8S1wZ0lfcQoMVraM5G3ShmoR9FNszv1EQzbg/b9EAKuZZLXoyd6NZ2OHjBOrQzbBW9/MtYQHq60m2znOq49/gpTano5EeIHgUFfrf30qZCvL3qcFZspkofpYHB7YsRz/87YAhZorQo7E5uyNKu4CMWkj3Y8JxUAdYYbuAZqFbVE7eTGl5
EOKNOWN

# vim: sw=2 ts=2 sts=2 et :
