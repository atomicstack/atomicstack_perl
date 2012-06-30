#!/usr/bin/perl

use strict;
use Data::Dumper;
use Sys::Hostname qw/hostname/;
use WebService::Prowl;
use File::Basename qw/basename/;

my $BATTERY_THRESHOLD = $ENV{BATTERY_WARNING_THRESHOLD} || 10;

( my $hostname = hostname() ) =~ s/[.].*//;

my $apikey = $ENV{PROWL_KEY} or die "missing PROWL_KEY environment variable";

my $ws = WebService::Prowl->new(apikey => $apikey);

my $prowl_app      = $hostname;
my $prowl_event    = basename $0;
my $prowl_priority = 2;
my $prowl_description;

my %status;

foreach ( qx{ /usr/sbin/ioreg -nAppleSmartBattery } ) {
  /\"(MaxCapacity)\"\s+=\s+(\d+)/     and $status{$1} = $2;
  /\"(CurrentCapacity)\"\s+=\s+(\d+)/ and $status{$1} = $2;
  /\"(IsCharging)\"\s+=\s+(\w+)/      and $status{$1} = $2;
}

my $percent_remaining = ( $status{CurrentCapacity} / $status{MaxCapacity} ) * 100;
$percent_remaining = sprintf '%.02f', $percent_remaining;
$status{IsCharging} ne 'Yes' and $percent_remaining < $BATTERY_THRESHOLD and $prowl_description = "$percent_remaining% remaining";

exit unless $prowl_description;

die $ws->error() unless
$ws->add('event' => $prowl_event, application => $prowl_app, description => $prowl_description, priority => $prowl_priority);
