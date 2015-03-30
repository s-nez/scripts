#!/usr/bin/env perl 
use strict;
use warnings;
use feature 'say';
binmode STDOUT, 'utf8';

my $tab        = ' ' x 4;
my $start_hlvl = 1;

@ARGV or die 'You need to specify a filename';
my ($filename) = @ARGV;
open my $FH, '<:utf8', $filename or die $!;

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

close $FH;
