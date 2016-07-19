package Respin;

use strict;
use warnings;
use DateTime;
use DateTime::Format::Duration;
use DateTime::Duration;
use JSON::XS;

my $iso8601_rx = qr{^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})$};

my $json = JSON::XS->new->utf8;

my $dur_fmt = DateTime::Format::Duration->new(
    normalize => 1,
    pattern =>
      q{{"week":"%V","day":"%u","hour":"%k","minute":"%M","second":"%S"}}
);

sub latest_src_age {
    my ( $now, $src ) = @_;

    print STDERR "Computing duration between [$src] and [$now]\n";

    my ( %now, %src );
    @now{qw(year month day hour minute second)} = ( $now =~ $iso8601_rx );
    @src{qw(year month day hour minute second)} = ( $src =~ $iso8601_rx );

    print $dur_fmt->format_duration_from_deltas(
        DateTime->new(%now)->subtract_datetime_absolute( DateTime->new(%src) )
          ->deltas );
}
