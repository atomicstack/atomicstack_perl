#!/usr/bin/env perl

use 5.14.0;

use IO::File;
use Regexp::Common qw/net/;
use POSIX qw/strftime/;

# use ip.seveas.net (thanks, dennis!) to update an ip history file and track
# when a host's ip changes

chomp( my @public_ips = IO::File->new($ARGV[0])->getlines );
my $current_ip;
my ($current_ip) = map { s/.*?$RE{net}{IPv4}{-keep}.*/$1/r } 
                 grep { m/whois[-]ip/ }
                 split /\n/ => qx{/usr/bin/wget -q -O - --timeout=5 http://ip.seveas.net};
                 # IO::File->new("seveas.html" => 'r')->getlines;

my ($previous_ip) = ( $public_ips[-1] =~ m/$RE{net}{IPv4}{-keep}/ );

chomp($current_ip, $previous_ip);

exit unless $current_ip =~ m/\A $RE{net}{IPv4} \z/xms;

if ( $previous_ip ne $current_ip ) {
    warn "$previous_ip ne $current_ip";
    IO::File->new($ARGV[0] => 'a')->print(strftime("[%F %T] $current_ip\n", localtime));
}
