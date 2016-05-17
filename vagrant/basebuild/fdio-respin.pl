#!/usr/bin/perl -wT

use strict;
use DateTime;
use URI;
use LWP::UserAgent;
use LWP::Simple qw(getstore);

my $vagrant_name = $ENV{VAGRANT_NAME} = 'kf7bmp-vagrant';
my $vexxhost_cp  = $ENV{VAGRANT_NAME} = 'fdio';
my $python_virtual = "/usr/src/git/lf/git.lf.org/cjcollier/python-virtual";
my $virtual_name   = 'fdio-openstack';
my $virtual_bin    = "$python_virtual/$virtual_name/bin";
my $sourcefile     = "$virtual_bin/activate";

my $codename_map = { trusty => '14.04',
                     xenial => '16.04' };

my $version_map = { '14.04' => 'trusty',
                    '16.04' => 'xenial' };

my $dt      = DateTime->now;
my @section = qw(year month day hour minute second);
my $isodate_notz = sprintf( '%s%s%sT%s%s%s',
                       ( map { $dt->$_ } @section ) );

my $yymm = $dt->format_cldr( 'yy' ) . sprintf('%02d', $dt->month - 1);
my $isodate = $isodate_notz . " " . $dt->format_cldr( 'ZZZZZ' );

my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;
$ua->show_progress(1);

sub upload_img {
  my( $dist, $version ) = @_;
  my %conf;
  if( $dist eq 'Ubuntu' ){
    my $cloudimg_root = "https://cloud-images.ubuntu.com/";
    my $codename = $version_map->{$version}
    $conf{disk_img_url} = "${cloudimg_root}/${codename}/current/${codename}-server-cloudimg-amd64-disk1.img";
  }elsif( $dist eq 'CentOS' ){
    my $cloudimg_root = "http://cloud.centos.org/centos/7/images/";
    $conf{disk_img_url} = "${cloudimg_root}/${dist}-${version}-x86_64-GenericCloud-$yymm.qcow2c";
  }elsif( $dist eq 'Debian' ){
    $conf{disk_img_url} = "...";
  }
  $conf{name} = sprintf('%s %s (%s) - LF upload', $dist, $version, $isodate);

  # TODO: download image file

  my $response = $ua->get($conf{disk_img_url});
  die $response->status_line unless $response->is_success;

  my $downloaded_file = "$dist-$version-$isodate_notz-base.img";

  LWP::Simple::getstore($conf{disk_img_url},$downloaded_file);

  # TODO: upload to openstack
  # my $result = qx{glance image-create --name '$conf{name}' --disk-format qcow2 --container-format bare --file $downloaded_file --progress};
}

my @ubuntu_releases = qw( trusty xenial );

sub abs_dir { $_[0] =~ qr{^/} && -d $_[0] }

my $uuid_regex =
  qr{[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}};

my $expected = {
  OS_REGION_NAME => sub { $_[0] =~ /^[a-z0-9-]+$/ }
  ,    # region wherein the OpenStack system exists
  VIRTUAL_ENV => sub { abs_dir $_[0] }
  ,    # directory containing python environment
  PATH => sub {
    my $paths = $_[0];
    $paths =~ qr{^/.+} or return 0;
    foreach my $path ( split( /:/, $paths ) ) {
      abs_dir( $path ) or return 0;
    }
    return 1;
  },    # directory names separated by colons
  OS_PASSWORD => sub { $_[0] =~ /^.+$/ },
  OS_AUTH_URL => sub {
    my $uri = URI->new( $_[0] );
    return 0 unless (     $uri->host
                      and $uri->path );
    return 1;
  },
  OS_USERNAME => sub {
    $_[0] =~ /$uuid_regex/;
  },
  OS_TENANT_NAME => sub {
    $_[0] =~ /$uuid_regex/;
  }, };

my $rx_str = '^(' . join( '|', keys %$expected ) . ')';
my $expected_rx = qr{$rx_str=(.+)$};

my $old_path = delete $ENV{PATH};
$ENV{PATH} = '/bin:/usr/bin';

foreach my $line (
           split( /\n/, qx{ echo '. $sourcefile; /usr/bin/env' | /bin/bash } ) )
{
  next
    unless $line =~ /$expected_rx/;
  my ( $key, $unchecked_val ) = ( $1, $2 );
  die( "invalid value for $key: $unchecked_val" ) unless $expected->{$key}->($unchecked_val);
  my ( $val ) = ( $unchecked_val =~ m:^(.+)$: );

  die "could not find valid value for [$key]" unless $val;

  $ENV{$key} = ${val};
}

my $nova_content = qx(nova image-list);

if ( $? != 0 ) {
  die( "failure executing nova: $!\n\n", "output was:\n", $nova_content );
}
my @nova_out = grep { $_ !~ /^\+/ } split( /\n/, $nova_content );
my $header_line = shift( @nova_out );

my $image = {};
foreach my $line ( @nova_out ) {
  my ( $bitbucket, @col ) = split(/\s*\|\s*/, $line);

  $image->{ $col[0] } = { uuid   => $col[0],
                          name   => $col[1],
                          status => $col[2],
                          server => $col[3], };
}

my $supported_distributions = { Ubuntu => { versions => [ '14.04', '16.04' ] },
                                CentOS => { versions => ['7'] } };
$ENV{RESEAL} = 'true';

foreach my $dist ( keys %$supported_distributions ) {
  print STDERR "now creating image of $dist distributions...\n";
  foreach my $version ( @{ $supported_distributions->{$dist}->{versions} } ) {

    my @img = sort
      grep { $_->{name} =~ /^$dist $version (.+) - LF upload$/ } values %$image;

    unless ( scalar @img > 0 ) {
      upload_img( $dist, $version  );
      redo;
#      print qq{No LF-uploaded base image for distribution "$dist $version"\n};
#      next;
    }

    print STDERR "now creating image of $dist $version...\n";
    my $upload_img = $img[-1];

    $ENV{IMAGE} = $upload_img->{name};

    print STDERR "Bringing vagrant system '$vagrant_name' online\n";
    system( qq{vagrant up --provider=openstack} );
    die "failed to bring vagrant system '$vagrant_name' online";
    print STDERR "Vagrant system $vagrant_name online... Make modifications and press enter when ready...";
    my $input = <STDIN>;

    # TODO: take a hint from STDIN
    my $new_name = qq{$dist $version - basebuild - $isodate};
    print STDERR "Now saving state of $vagrant_name as '$new_name'\n";
    system( qq{nova image-create --poll $vagrant_name '$new_name' } );
    print STDERR "Vagrant system cloned.  Now destroying vagrant system.\n";
    system( qq{vagrant destroy} );
    print STDERR "Vagrant system $vagrant_name has now been destroyed\n";
  }
}
