#!/usr/bin/env perl

# convert bash_history to zsh_history

use 5.14.2;
use warnings;

use IO::File;

my $input_file = $ARGV[0] || die "usage: $0 /path/to/valid/file";
my $output_file = "${input_file}.zsh";

unless (-f $ARGV[0] and -r $ARGV[0]) {
  die "can't read $input_file";
}

if (-f $output_file) {
  die "won't clobber existing output_file=$output_file";
}

my @lines = IO::File->new($ARGV[0] => 'r')->getlines;

chomp(@lines);

my $total_lines = @lines;
my $line_counter = 0;

my %seen_commands;
my @output_commands;

my @skipped_lines;

my $epoch_regexp = qr/^[#]\s*[0-9]+\s*\z/;
my $empty_regexp = qr/\A\s*\z/;

LINE:
while (my ($line_counter, $this_line) = each @lines) {
  my $this_line = $lines[ $line_counter ];
  my $prev_line = $lines[ $line_counter - 1 ] // '-+-';
  my $next_line = $lines[ $line_counter + 1 ] // '=+=';

  next unless defined $prev_line;

  die "dead line=$line_counter" if $this_line =~ m/$empty_regexp/;

  if ($this_line =~ m/$epoch_regexp/) {
    # warn "found epoch regexp at line=$line_counter, skipping";
    next LINE;
  }
  else {
    ( my $epoch = $prev_line ) =~ s/[^0-9]//g;
    push @output_commands, ": $epoch:0;$this_line\n";
  }
}

IO::File->new($output_file => 'w')->print(@output_commands);
