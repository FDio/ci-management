#!/usr/bin/perl -w

use strict;
use File::Path;
use DateTime;

my $dt      = DateTime->now;
my @section = qw(year month day hour minute second);
my $isodate_notz = sprintf( '%s%s%sT%s%s%s',
                       ( map { $dt->$_ } @section ) );

my $yymm = $dt->format_cldr( 'yy' ) . sprintf('%02d', $dt->month - 1);
my $isodate = $isodate_notz . " " . $dt->format_cldr( 'ZZZZZ' );

my @root_img =
  map { s/^\s*(.+\S)\s*$/$1/; $_ }
  split( /\n/,
    qx{glance image-list | awk -F'|' '/LF upload/ {print \$3}' | sort} );

my $distmap = {
    ubuntu1404 => 'Ubuntu 14.04',
    ubuntu1604 => 'Ubuntu 16.04',
    centos7    => 'CentOS 7',
};

qx{vagrant destroy 2>/dev/null};
File::Path::rmtree('.vagrant');

$ENV{RESEAL} = 1;

while( my( $dist, $name ) = each %$distmap ){
  $ENV{IMAGE} = ( sort grep { /$name/ } @root_img )[0];
  system(qq{vagrant up});
  system(qq{nova image-create --poll $ENV{USER}-vagrant '$name - basebuild - $isodate_notz'});
  system(qq{vagrant destroy});
}
