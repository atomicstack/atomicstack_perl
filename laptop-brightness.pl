#!/usr/bin/env perl

use 5.14.2;
use warnings;

use Data::Dumper;

# LG 4k
# ddcctl -d 1 -b 10-
# ddcctl -d 1 -b 10+

# built-in
# brightness -d 1 -v $VALUE

# fork suffix
my $fs = '&>/dev/null &';

sub increase {
  system("brightness -d 1 @{[ get_builtin_brightness() + 0.1 ]} $fs");
  system("ddcctl -d 1 -b 10+ $fs");
}

sub decrease {
  system("brightness -d 1 @{[ get_builtin_brightness() - 0.1 ]} $fs");
  system("ddcctl -d 1 -b 10- $fs");
}

sub get_builtin_brightness {
  chomp( my @lines = qx{brightness -l 2>/dev/null} );
  my @builtin_status = split /\s+/ => $lines[-1];

  # warn Dumper(\@builtin_status);

  return $builtin_status[2] eq 'brightness' 
    ? $builtin_status[3]
    : ();
}

my %subs = (
    increase => \&increase,
    decrease => \&decrease,
    up       => \&increase,
    down     => \&decrease,
);

my $sub = ( $ARGV[0] and exists $subs{$ARGV[0]} ) ? $subs{$ARGV[0]} : undef;

die "usage: $0 <up|down|increase|decrease>" unless ( $ARGV[0] and $sub );

$sub->();
