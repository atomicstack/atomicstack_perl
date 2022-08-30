#!/usr/bin/env perl

use 5.14.2;
use warnings;

use Data::Dumper;
use Sys::Hostname qw/hostname/;
use Getopt::Long;

GetOptions(
  'identity_file=s' => \(my $identity_file),
  'repository=s'    => \(my $repo_dir),
  'verbose+'        => \(my $verbose),
);

$identity_file or die "no identity_file parameter found";
-r $identity_file or die "missing/unreadable identity file $identity_file";

$repo_dir or die "no repo_dir parameter found";
-d $repo_dir or die "bad repo dir $repo_dir";

chdir $repo_dir;

$ENV{GIT_SSH_COMMAND} = qq{ssh -v -o ClearAllForwardings=yes -o "IdentitiesOnly=yes" -i $identity_file};
my @output = qx{git fetch --multiple origin xort 2>&1};
my $exit_signal = $? >> 127;
my $exit_code = $? >> 8;

if    ($exit_signal) { warn "git fetch died of signal $exit_signal" }
elsif ($exit_code)   { warn "git fetch terminated with exit code $exit_code" }

( $exit_signal or $exit_code or $verbose ) and say @output;
