#!/usr/bin/perl
use strict;
use warnings;
use feature 'say';
use Encode 'decode_utf8';
use Getopt::Std;

binmode STDOUT, 'utf8';

my $tab = ' ' x 4;
my ($min_hlvl, $max_hlvl) = (1, 4); # TODO: Make this configurable

my ($start_delim, $end_delim) = ('<!--TOC_START--->', '<!--TOC_END--->');

# Commandline options
our $opt_d = 0;     # add delimeters to the ToC
our $opt_w = 0;     # write the ToC into the source file
our $opt_t = '';    # add a custom title for the ToC
getopt('t');
getopts('dw');

@ARGV or die 'You need to specify a filename';
my ($filename) = @ARGV;
open my $FH, '<:utf8', $filename or die $!;

my @toc;
push @toc, $start_delim if $opt_d;
push @toc, '#' x ($min_hlvl + 1) . ' ' . decode_utf8($opt_t) if $opt_t;
while (<$FH>) {
    if (/\A#{$min_hlvl}(#+) (.+)\Z/) {
        next if length($1) + $min_hlvl > $max_hlvl;
        chomp;
        my $lvl   = length($1) - $min_hlvl;
        my $title = $2;
        my $link  = lc $title;
        $link =~ s/\s+/-/g;
        $link =~ s/[^\w-]//gu;
        push @toc, $tab x $lvl . "* [$title](#$link)";
    }
}

# newline required for Markdown to treat this as a comment
push @toc, "\n" . $end_delim if $opt_d;

unless ($opt_w) {
    close $FH;
    say foreach @toc;
    exit 0;
}

# Option -w selected
my $toc_status = 'before';             # possible values: before, inside, after
my $tmp_file   = "/tmp/ghtocgen-$$";
open my $TMP, '>:utf8', $tmp_file or die $!;
seek $FH, 0, 0;

while (<$FH>) {
    if ($toc_status eq 'before') {
        if (index($_, $start_delim) != -1) {
            say $TMP $_ foreach @toc;
            $toc_status = 'inside';
        } else {
            print $TMP $_;
        }
    } elsif ($toc_status eq 'inside') {
        if (index($_, $end_delim) != -1) {
            $toc_status = 'after';
        }
    } else {
        print $TMP $_;
    }
}

close $FH;
close $TMP;

if ($toc_status eq 'before') {
    say 'ERROR: No starting delimeter found';
    unlink $tmp_file;
    exit 1;
} elsif ($toc_status eq 'inside') {
    say 'ERROR: No ending delimeter found';
    unlink $tmp_file;
    exit 1;
} else {
    use File::Copy 'move';
    move($tmp_file, $filename);
}
