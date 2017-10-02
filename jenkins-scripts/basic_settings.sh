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
[gerrit.fd.io]:29418,[162.253.54.31]:29418 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC76FxV43JIk/HpI5JUZfizmak9znK/QzsjPoNHt/Eo2Vp68kvJIRZ+PzI7RJR0NsdsXlyqzRsGuH+Cj99ZuLVjNMqz1Y1A5y6itYAgT42KDcnV/JoPx6WV+THdQ+oMSp2dINtvD1kc6Om8iAA2CwYOfIZ/FQS5A9OX2xzFopo4qAN3nRk9kpcHyC698R5SDNZBbk6eqlsBz0827KJrSpOSEEMBhtroBM4JV8vImcSWeJuQ5QFdZgQdQaI8R5YFBRbWu3mDSgJfjJk89xT2CkUiqIynNJeiQMM4IZxcdQB3zJ1RUEJepxv77yV09NZ8jwhaN6X659UJZjsCZ5ffvc77
EOKNOWN

# vim: sw=2 ts=2 sts=2 et :
