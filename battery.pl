#!/usr/bin/perl

use strict;
use Data::Dumper;
use Sys::Hostname qw/hostname/;
use File::Basename qw/basename/;

$Data::Dumper::Sortkeys = 1;

my $BATTERY_THRESHOLD = $ENV{BATTERY_WARNING_THRESHOLD} || 15;

( my $hostname = hostname() ) =~ s/[.].*//;

my $message;

my %status;

foreach ( qx{ /usr/sbin/ioreg -nAppleSmartBattery } ) {
  /\"(CycleCount)\"\s+=\s+(\d+)/            and $status{$1} = $2;
  /\"(MaxCapacity)\"\s+=\s+(\d+)/           and $status{$1} = $2;
  /\"(CurrentCapacity)\"\s+=\s+(\d+)/       and $status{$1} = $2;
  /\"(DesignCapacity)\"\s+=\s+(\d+)/        and $status{$1} = $2;
  /\"(ExternalChargeCapable)\"\s+=\s+(\w+)/ and $status{$1} = $2;
  /\"(ExternalConnected)\"\s+=\s+(\w+)/     and $status{$1} = $2;
}

my $percent_remaining = ( $status{CurrentCapacity} / $status{MaxCapacity} ) * 100;
my $percent_remaining = $status{percent_remaining} = sprintf '%.02f', $percent_remaining;
my $percent_degraded  = sprintf '%.04f', 100 - ( ( $status{MaxCapacity} / $status{DesignCapacity} ) * 100 );

my $should_alert = ( $status{ExternalChargeCapable} ne 'Yes' and $percent_remaining < $BATTERY_THRESHOLD );
$should_alert and $message = "$percent_remaining% remaining";

$ENV{DEBUG} and print Dumper({
    %status,
    message => $message,
    battery_threshold => $BATTERY_THRESHOLD,
    percent_degraded => $percent_degraded,
    battery_is_below_threshold => ( $percent_remaining < $BATTERY_THRESHOLD ),
});

exit unless ( $should_alert and $message );

my @prowl_command = (
    "$ENV{HOME}/bin/prowl" =>
    '-a' => basename($0),
    '-t' => $hostname,
    '-m' => $message,
);

$ENV{DEBUG} and print Dumper(\@prowl_command);

system @prowl_command;
