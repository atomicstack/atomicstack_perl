#!/usr/bin/env perl5.26.0

use 5.14.2;
use warnings;

use Data::Dumper;
use File::Basename;
use Getopt::Long;
use Image::ExifTool;

my $LAME = '/usr/local/bin/lame';

my %command_line_args;

GetOptions(
    'input|input_filename|input-filename=s'    => \( $command_line_args{input_filename}  ),
    'output|output_filename|output-filename=s' => \( $command_line_args{output_filename} ),
    'encoding_profile=s' => \( $command_line_args{encoding_profile} ),
);

if (not -r $command_line_args{input_filename}) {
    die "input_filename $command_line_args{input_filename} is unreadable/missing";
}

if (not $command_line_args{output_filename}) {
    die "failed to auto-generate aiff -> mp3 output_filename" unless
    (my $output_filename = File::Basename::basename($command_line_args{input_filename})) =~ s/[.]aiff$/.mp3/;
    $command_line_args{output_filename} = $output_filename;
}

if (-f $command_line_args{output_filename}) {
    die "output_filename $command_line_args{output_filename} already exists!";
}

$command_line_args{encoding_profile} ||= 'V0';
$command_line_args{encoding_profile} = uc $command_line_args{encoding_profile};

if ($command_line_args{encoding_profile} !~ /^V[0-9]/) {
    die "invalid encoding_profile $command_line_args{encoding_profile}";
}

my $exiftool = Image::ExifTool->new();

my %info = %{ $exiftool->ImageInfo($command_line_args{input_filename}) };

my @picture_keys = grep { $_ =~ /Picture( \s+ [(][0-9]+[)] )?\z/xms } keys %info;
delete @info{@picture_keys};

# die Dumper(\%info);

my @lame_command_line_args = (
    "-$command_line_args{encoding_profile}",
    # '--add-id3v2',
    '--id3v2-only',
    '--id3v2-utf16',
    '--tt' => $info{Title},
    '--ta' => $info{Artist},
    '--tl' => $info{Album},
    $command_line_args{input_filename},
    $command_line_args{output_filename},
);

say "about to execute: $LAME @lame_command_line_args";
system $LAME, @lame_command_line_args;
