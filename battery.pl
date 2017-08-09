#!/usr/bin/perl

use strict;
use Data::Dumper;
use Sys::Hostname qw/hostname/;
use File::Basename qw/basename/;

my $BATTERY_THRESHOLD = $ENV{BATTERY_WARNING_THRESHOLD} || 10;

( my $hostname = hostname() ) =~ s/[.].*//;

my $message;

my %status;

foreach ( qx{ /usr/sbin/ioreg -nAppleSmartBattery } ) {
  /\"(MaxCapacity)\"\s+=\s+(\d+)/     and $status{$1} = $2;
  /\"(CurrentCapacity)\"\s+=\s+(\d+)/ and $status{$1} = $2;
  /\"(IsCharging)\"\s+=\s+(\w+)/      and $status{$1} = $2;
}

$ENV{DEBUG} and print Dumper(\%status);

my $percent_remaining = ( $status{CurrentCapacity} / $status{MaxCapacity} ) * 100;
$percent_remaining = sprintf '%.02f', $percent_remaining;
$status{IsCharging} ne 'Yes' and $percent_remaining < $BATTERY_THRESHOLD and $message = "$percent_remaining% remaining";

exit unless $message;

my @prowl_command = (
    "$ENV{HOME}/bin/prowl" =>
    '-a' => basename($0),
    '-t' => $hostname,
    '-m' => $message,
);

$ENV{DEBUG} and print Dumper(\@prowl_command);

system @prowl_command;
