#!/usr/bin/perl -wT

# @License EPL-1.0 <http://spdx.org/licenses/EPL-1.0>
##############################################################################
# Copyright (c) 2016 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   C.J. Collier (The Linux Foundation) - Initial implementation
##############################################################################

use strict;
use File::Basename;
use File::Spec;
use Cwd qw{abs_path};

delete $ENV{PATH};

my $hex_octet_rx  = qr{[0-9a-fA-F]{2}};
my $hex_double_rx = qr{[0-9a-fA-F]{4}};
my $lladdr_rx     = qr{$hex_octet_rx(?::$hex_octet_rx){5}};

my $dec_octet_rx = qr{(?:25[0-5]|2[0-4]\d|[01]?\d{1,2})};
my $v4addr_rx    = qr{$dec_octet_rx(?:\.$dec_octet_rx){3}};

# TODO: $v6addr_rx

# https://www.kernel.org/doc/Documentation/filesystems/sysfs-pci.txt
# http://prefetch.net/articles/linuxpci.html
# pci path components are numbered such:
my $pci_rx = {

  # domains  from 0 to ffff
  domain => $hex_double_rx,

  # bus number      from 0 to ff
  bus => $hex_octet_rx,

  # slot     from 0 to 1f
  slot => qr{[01][0-9a-fA-F]},

  # device function from 0 to 7
  func => qr{[0-7]},
  path => {} };

# examples:
# 0000:00:00.0 (Primary host bridge)
# Devices on primary host bridge
#   0000:00:1c.1 (PCIe bridge)
#     0000:02:00.0 (802.11 Wireless NIC)
#   0000:00:1c.2 (PCIe bridge)
#     0000:03:00.0 (MMC/SD Host Controller)
#   0000:00:1e.0 (PCI bridge)
#   0000:00:1f.0 (ISA bridge)
#   0000:00:1f.3 (SMBus bridge)
# 0000:3f:00.0 (Secondary host bridges)

$pci_rx->{devstr} =
qr{($pci_rx->{domain}):($pci_rx->{bus}):($pci_rx->{slot})\.($pci_rx->{func})};

my $sysroot = '/sys';

my $sysdev_root = File::Spec->catfile( $sysroot, 'devices' );

my $ppath_rx = $pci_rx->{path};

# examples:
# /sys/devices/pci0000:00
# /sys/devices/pci0000:3f
$ppath_rx->{hostbr} = qr{$sysdev_root/pci(($pci_rx->{domain}):($pci_rx->{bus}))};

# examples:
# /sys/devices/pci0000:00/0000:00:02.0 (Graphics Controller)
# /sys/devices/pci0000:00/0000:00:19.0 (Wired NIC on laptop and desktop)
$ppath_rx->{hostdev} = $ppath_rx->{pcibr} =
  qr{$ppath_rx->{hostbr}/\1:($pci_rx->{slot})\.($pci_rx->{func})};

# examples:
# /sys/devices/pci0000:00/0000:00:1c.1/0000:02:00.0 (802.11 Wireless NIC on laptop)
# /sys/devices/pci0000:00/0000:00:1c.2/0000:03:00.0 (MMC/SD Host Controller on laptop)
# /sys/devices/pci0000:00/0000:00:1c.4/0000:02:00.0 (802.11 Wireless NIC on desktop)
$ppath_rx->{extdev} = qr{$ppath_rx->{pcibr}/($pci_rx->{devstr})};

# examples:
# /sys/devices/pci0000:00/0000:00:19.0/net/eth0 (Wired NIC on laptop and desktop)
$ppath_rx->{hostnic} = qr{$ppath_rx->{hostdev}/net/([^/]+)$};

# examples:
# /sys/devices/pci0000:00/0000:00:1c.1/0000:02:00.0/net/wlan0 (802.11 Wireless NIC on laptop)
# /sys/devices/pci0000:00/0000:00:1c.4/0000:02:00.0/net/wlan0 (802.11 Wireless NIC on desktop)
$ppath_rx->{extnic} = qr{$ppath_rx->{extdev}/net/([^/]+)$};

my $usb_rx = {
  hubname       => qr{usb\d+},
  hubno         => qr{\d+},
  busnum        => qr{\d+},
  port          => qr{\d+},
  config_num    => qr{\d+},
  interface_num => qr{\d+},
  path          => {}

    # root_hub-hub_port:config.interface
    # bus-port.port.port:config.interface
};

# examples:
# /sys/devices/pci0000:00/0000:00:1a.0/usb1/1-1/1-1.2/1-1.2.2/1-1.2.2:1.0/net/usb1
# /sys/devices/pci0000:00/0000:00:1a.0/usb1/1-1/1-1.2/1-1.2.1/1-1.2.1:1.0/net/usb2
#$ppath_rx->{usbnic} = qr{$ppath_rx->{hostdev}/($usb_rx->{hubname})/($usb_rx->{hubno})-($usb_rx->{busnum})([^/]+)$};
$ppath_rx->{usbnic} = qr{$ppath_rx->{hostdev}/(.+)/net/([^/]+)$};

# examples:
# /sys/devices/pci0000:00/0000:00:03.0/virtio0/net/eth0
# /sys/devices/pci0000:00/0000:00:03.0/virtio0/net/ens3
# TODO: get examples for Xen devices
$ppath_rx->{pvnic} = qr{$ppath_rx->{hostdev}/virtio\d+/net/([^/]+)$};

# examples:
# /sys/devices/virtual/net/gre0
# /sys/devices/virtual/net/gretap0
# /sys/devices/virtual/net/lo
# /sys/devices/virtual/net/mgmt0
# /sys/devices/virtual/net/mtik0
# /sys/devices/virtual/net/sip0
# /sys/devices/virtual/net/tani

my $vnetpath_rx = qr{^$sysdev_root/virtual/net/(.+)$}x;

# examples:
#   1: lo:                <LOOPBACK,UP,LOWER_UP>                    mtu 65536 qdisc noqueue                   state UNKNOWN mode DEFAULT group default            link/loopback 00:00:00:00:00:00 brd  00:00:00:00:00:00                # loopback
#   2: eth0:              <BROADCAST,MULTICAST,UP,LOWER_UP>         mtu 1500  qdisc pfifo_fast master vmbr0   state UP      mode DEFAULT group default qlen 1000  link/ether    d4:3d:7e:e1:e3:cb brd  ff:ff:ff:ff:ff:ff                # physical pcie NIC
#   2: ens3:              <BROADCAST,MULTICAST,UP,LOWER_UP>         mtu 1500  qdisc pfifo_fast                state UP      mode DEFAULT group default qlen 1000  link/ether    52:54:00:da:a3:aa brd  ff:ff:ff:ff:ff:ff                # guest-side KVM pv NIC
#   3: wlan0:             <BROADCAST,MULTICAST>                     mtu 1500  qdisc noop                      state DOWN    mode DEFAULT group default qlen 1000  link/ether    48:d2:24:52:d7:4c brd  ff:ff:ff:ff:ff:ff                # 802.11 NIC
#   4: vmbr0:             <BROADCAST,MULTICAST,UP,LOWER_UP>         mtu 1500  qdisc noqueue                   state UP      mode DEFAULT group default qlen 1000  link/ether    d4:3d:7e:e1:e3:cb brd  ff:ff:ff:ff:ff:ff                # bridge
#   6: vnet0:             <BROADCAST,MULTICAST,UP,LOWER_UP>         mtu 1500  qdisc noqueue    master vmbr0   state UNKNOWN mode DEFAULT group default qlen 500   link/ether    fe:54:00:da:a3:aa brd  ff:ff:ff:ff:ff:ff                # host-side KVM pv NIC
#   6: gre0@NONE:         <NOARP>                                   mtu 1476  qdisc noop                      state DOWN    mode DEFAULT group default            link/gre      0.0.0.0           brd  0.0.0.0                          # root GRE or something
#   7: gretap0@NONE:      <BROADCAST,MULTICAST>                     mtu 1462  qdisc noop                      state DOWN    mode DEFAULT group default qlen 1000  link/ether    00:00:00:00:00:00 brd  ff:ff:ff:ff:ff:ff                # GRE tuntap device
#  10: tun0:              <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1412  qdisc noqueue                   state UNKNOWN mode DEFAULT group default qlen 500   link/none                                                             # vpnc tunnel device - tuntap?
#  10: usb1:              <BROADCAST,MULTICAST,UP,LOWER_UP>         mtu 1500  qdisc pfifo_fast                state UP      mode DEFAULT group default qlen 1000  link/ether    40:3c:fc:01:35:a5 brd  ff:ff:ff:ff:ff:ff                # 100Mbit USB NIC
#  12: sip0@NONE:         <POINTOPOINT,NOARP>                       mtu 1414  qdisc noop                      state DOWN    mode DEFAULT group default            link/gre      100.64.106.2      peer 100.64.106.1                     # GRE tunnel
#  15: mgmt0@eth0:        <BROADCAST,MULTICAST,UP,LOWER_UP>         mtu 1500  qdisc noqueue                   state UP      mode DEFAULT group default            link/ether    00:26:b9:e3:9b:47 brd  ff:ff:ff:ff:ff:ff                # VLAN interface
# 229: veth0951c45@if228: <BROADCAST,MULTICAST,UP,LOWER_UP>         mtu 1500  qdisc noqueue    master docker0 state UP      mode DEFAULT group default            link/ether    76:06:fe:f2:99:bc brd  ff:ff:ff:ff:ff:ff link-netnsid 1 # Docker virtual NIC host side
# 228: eth0@if229:        <BROADCAST,MULTICAST,UP,LOWER_UP>         mtu 1500  qdisc noqueue                   state UP      mode DEFAULT group default            link/ether    02:42:ac:1e:00:02 brd  ff:ff:ff:ff:ff:ff                # Docker virtual NIC guest side
# 232: caftun:            <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500  qdisc noqueue                   state UNKNOWN mode DEFAULT group default qlen 100   link/none                                                             # caf tunnel tuntap

# TODO: bond, ip6gre, sit, ipip
my $iface_rx = qr{^(
       # 3:
       (\d+):\s+
       # wlan0:
       ([^@]+)(?:@([^:]+))?:\s+
       # <BROADCAST,MULTICAST>
       <([^>]+)>\s+
       # mtu 1500
       mtu\s+(\d+)\s+
       # qdisc noop
       qdisc\s+(\S+)\s+
       # master docker0
       (?:master\s+(\S+)\s+)?
       #state UNKNOWN
       state\s+(\S+)\s+
       #mode DEFAULT
       mode\s+(\S+)\s+
       #group default
       group\s+(\S+)\s+
       #qlen 500
       (?:qlen\s+(\S+)\s+)?
       # link/ether
       link/(\S+)\s+

       (?:
         # fe:54:00:da:a3:aa brd ff:ff:ff:ff:ff:ff
         ($lladdr_rx)\s+brd\s+($lladdr_rx)|
         # 100.64.106.2 peer 100.64.106.1
         ($v4addr_rx)\s+peer\s+($v4addr_rx)
       )?\s*
       # link-netnsid 0
       (?:link-netnsid\s+(\d+))?
     )$}x;

foreach my $devpath ( map { chomp $_; $_ } glob( q{/sys/class/net/*} ) ) {

  my $syspath;
  if ( -l $devpath ) {
    $syspath = abs_path( $devpath );
  } else {
    $syspath = $devpath;
  }

  my ( $type, %match );
  ($match{syspath}) = ( $syspath =~ /^(.+)$/ );
  if ( my ( @matches ) = ( $syspath =~ $ppath_rx->{hostnic} ) ) {
    $type = 'Host';
    @match{qw( dom_bus domain busno slot func devname )} = @matches;
  } elsif ( ( @matches ) = ( $syspath =~ $ppath_rx->{extnic} ) ) {
    $type = 'External';
    @match{qw( dom_bus domain busno hubslot hubfunc devstr devdom devbus devslot devfunc devname )} = @matches;
  } elsif ( ( @matches ) = ( $syspath =~ $ppath_rx->{usbnic} ) ) {
    $type = 'USB';
    @match{qw( dom_bus domain busno hubslot hubfunc usbpath devname )} = @matches;
  } elsif ( ( @matches ) = ( $syspath =~ $ppath_rx->{pvnic} ) ) {
    die( "paravirt NIC\n", $syspath, "\n", join( "\n", @matches ) );
  } elsif ( ( @matches ) = ( $syspath =~ $vnetpath_rx ) ) {
    $type = 'Virtual';
    @match{qw( devname )} = @matches;
  } else {
    # /sys/devices/pci0000:00/0000:00:19.0/net/eth0
    # qr{($pci_rx->{domain}):($pci_rx->{bus}):($pci_rx->{slot})\.($pci_rx->{func})};
    # qr{$ppath_rx->{hostbr}/\1:($pci_rx->{slot})\.($pci_rx->{func})};
    ( @matches ) = ( $syspath =~ /($ppath_rx->{hostdev})/g );
    print( join( "\n", @matches ), "\n" );
    #die( "no match!\n$pci_rx->{devstr}\n$syspath" );
    die( "no match!\n$ppath_rx->{hostdev}\n$syspath" );
  }

  my $linkline =
    join( "", map { chomp $_; $_ } qx{/sbin/ip link show dev $match{devname}} );
  my ( $all,      $ifid,   $ifdev, $pdev,    $flags, $mtu,
       $qdisc,    $master, $state, $mode,    $group, $qlen,
       $linktype, $lladdr, $llbrd, $localv4, $remotev4
  ) = map { $_ or '' } ( $linkline =~ $iface_rx );
  print(
    "====================\n",
    "--- $type ---\n",
    ( map { sprintf( "%-8s: [$match{$_}]\n", $_ ) } keys %match ),
    "--- Interface ---\n",
    "all:    [$all]\n",
    "ifid:   [$ifid]\n",
    "ifdev:  [$ifdev]\n",
    "flags:  [$flags]\n",
    ( $pdev ? ( "pdev:   [$pdev]\n", ) : () ),
    "mtu:    [$mtu]\n",
    "qdisc:  [$qdisc]\n",
    ( $master ? ( "master: [$master]\n" ) : () ),
    "state:  [$state]\n",
    "mode:   [$mode]\n",
    "group:  [$group]\n",
    ( $qlen ? ( "qlen:   [$qlen]\n" ) : () ),
    "type:   [$linktype]\n",
    ( $lladdr  ? ( "lladdr: [$lladdr]\n", "llbrd:  [$llbrd]\n", )     : () ),
    ( $localv4 ? ( "local: [$localv4]\n", "remote:  [$remotev4]\n", ) : ()
    ),
    "====================\n\n", );
}
