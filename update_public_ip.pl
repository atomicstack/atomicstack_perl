#!/usr/bin/env perl

use 5.14.0;

use IO::File;
use Regexp::Common qw/net/;
use POSIX qw/strftime/;
use Sys::Hostname;

( my $hostname = hostname() ) =~ s/[.].*//;

# use ip.xort.nl to update an ip history file and
# track when a host's ip changes

chomp( my @public_ips = IO::File->new($ARGV[0])->getlines );
my $current_ip;

chomp ( my $current_ip = qx{/usr/bin/wget -q -O - --timeout=5 http://ip.xort.nl:3000} );

my ($previous_ip) = ( $public_ips[-1] =~ m/$RE{net}{IPv4}{-keep}/ );

chomp($current_ip, $previous_ip);

exit unless $current_ip =~ m/\A $RE{net}{IPv4} \z/xms;

if ( $previous_ip ne $current_ip ) {
    warn "$previous_ip ne $current_ip" if -t \*STDOUT;
    system qq|$ENV{HOME}/bin/prowl -a 'update_public_ip.pl' -t $hostname -m "$current_ip"|;
    IO::File->new($ARGV[0] => 'a')->print(strftime("[%F %T] $current_ip\n", localtime));
}
