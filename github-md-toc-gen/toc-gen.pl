#!/usr/bin/env perl 
use strict;
use warnings;
use feature 'say';
use Getopt::Std;

binmode STDOUT, 'utf8';

my $tab        = ' ' x 4;
my $start_hlvl = 1;

my ($start_delim, $end_delim) = ('<!--TOC_START--->', '<!--TOC_END-->');

# Commandline options 
our $opt_d = 0; # add delimeters to the ToC
our $opt_w = 0; # write the ToC into the source file (TODO)
getopts('dw');

@ARGV or die 'You need to specify a filename';
my ($filename) = @ARGV;
open my $FH, '<:utf8', $filename or die $!;

say $start_delim if $opt_d;
while (<$FH>) {
    if (/\A#{$start_hlvl}(#+) (.+)\Z/) {
        chomp;
        my $lvl   = length $1;
        my $title = $2;
        my $link  = lc $title;
        $link =~ s/\s+/-/g;
        $link =~ s/[^\w-]//gu;
        say $tab x $lvl, "* [$title](#$link)";
    }
}
say $end_delim if $opt_d;
close $FH;
