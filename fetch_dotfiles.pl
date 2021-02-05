#!/usr/bin/env perl

use 5.14.2;
use warnings;

use Sys::Hostname qw/hostname/;

chdir "$ENV{HOME}/.dotfiles";

# filename format determined by:
# https://gist.github.com/atomicstack/696fa0ba8473adc842c0fecfe8068b7d

# keyname=$(printf "%s_dotfiles_deploy_%s" $(hostname -s) $(date +%F))
# ssh-keygen -C $keyname -f "$HOME/.ssh/${keyname}.pem" -t ed25519 -N ""

my ($hostname) = map { s/[.].*//r } hostname();
my ($key_filename) = grep { m/${hostname}_dotfiles_deploy_\d{4}-\d{2}-\d{2}/ } glob "$ENV{HOME}/.ssh/*dotfiles_deploy*.pem";
die "couldn't find key filename :(" unless ( $key_filename and -f $key_filename );

$ENV{GIT_SSH_COMMAND} = qq{ssh -v -o ClearAllForwardings=yes -o "IdentitiesOnly=yes" -i $key_filename};
my @output = qx{git fetch --all 2>&1};
my $exit_signal = $? >> 127;
my $exit_code = $? >> 8;

if    ($exit_signal) { warn "git fetch died of signal $exit_signal" }
elsif ($exit_code)   { warn "git fetch terminated with exit code $exit_code" }

( $exit_signal or $exit_code ) and say @output;
