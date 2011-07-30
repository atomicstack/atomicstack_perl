#!/usr/bin/env perl

use 5.010;
use strict;

use LWP::UserAgent;
use POSIX qw/strftime/;
use Regexp::Common qw/net/;
use URI::Escape;
use DBI;

BEGIN {
  use constant DEBUG => $ENV{NOIP_DEBUG};
  exit if 1 < grep {/no_ip.pl/} split /\n/, qx{ps auxww};
}

my $hostname = 'foo.no-ip.org';
my $email    = 'user@example.org';
my $pass     = 'password';
my $ip_url   = 'http://www.whatismyip.org';

my $dbh = DBI->connect("dbi:SQLite:$ENV{HOME}/.ips.db");
my $ua  = LWP::UserAgent->new;

my $info = $ua->get($ip_url);
DEBUG and say "$ip_url response: ".$info->decoded_content;
$info->decoded_content =~ m/$RE{net}{IPv4}{-keep}/ or exit;

my $ip = $1;
DEBUG and say "extracted ip: $ip";
$ip =~ m/\A (10|127|192[.]168|169[.]254)[.] /xms and exit;

my $old_ip = $dbh->selectrow_array('SELECT ip FROM ips ORDER by id DESC LIMIT 1');

if ($old_ip and not @ARGV) {
  DEBUG and say "exit if $ip eq $old_ip";
  exit if $ip eq $old_ip;
  my $ssid = get_ssid();
  $dbh->do( "INSERT INTO ips (id, ip, ssid, time) VALUES (NULL, ?, ?, ?)", undef, $ip, $ssid, strftime('%F %T', localtime) );
  IO::File->new("$ENV{HOME}/Dropbox/ips/$hostname.txt" => 'a')->say($ip);
}

my $noip_url = sprintf 'http://%s:%s@dynupdate.no-ip.com/nic/update?hostname=%s&myip=%s', 
               uri_escape($email), uri_escape($pass), $hostname, $ip;

my $update = $ua->get($noip_url);
DEBUG and say "$noip_url response:\n" . $update->decoded_content;

sub get_ssid {
  my ($ssid) = grep {m/ SSID:/} qx{/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null};
  chomp $ssid;
  $ssid =~ s/.*SSID: //;
  return $ssid;
}
