#!/usr/bin/perl
use strict;
use warnings;
use feature 'say';
use Encode 'decode_utf8';
use Getopt::Std;
binmode STDOUT, 'utf8';

my $tab = ' ' x 4;
my ($min_hlvl, $max_hlvl) = (1, 4);
my ($start_delim, $end_delim) = ('<!--TOC_START--->', '<!--TOC_END--->');

# Commandline options
our $opt_d = 0;                        # add delimeters to the ToC
our $opt_w = 0;                        # write the ToC into the source file
our $opt_s = 0;                        # starting heading level ($min_hlvl)
our $opt_e = 0;                        # ending heading level ($max_hlvl)
our $opt_t = '';                       # add a custom title for the ToC
getopt('tse');
getopts('dw');
$min_hlvl = $opt_s if $opt_s;
$max_hlvl = $opt_e if $opt_e;

sub toc_add(\@$$) {
    my ($toc, $raw_level, $title) = @_;
    return if length($raw_level) + $min_hlvl > $max_hlvl;

    my $lvl = length($raw_level) - $min_hlvl;
    $title =~ s/\s+$//;                # remove trailing whitespace
    my $link = lc $title;
    $link =~ s/\s+/-/g;
    $link =~ s/[^\w-]//gu;
    push @$toc, $tab x $lvl . "* [$title](#$link)";
}

@ARGV or die 'You need to specify a filename';
my ($filename) = @ARGV;
open my $SOURCE, '<:utf8', $filename or die $!;

my @toc;
push @toc, $start_delim if $opt_d;
push @toc, '#' x ($min_hlvl + 1) . ' ' . decode_utf8($opt_t) if $opt_t;

my $toc_status  = 'before';    # possible values: before, inside, after
my %parse_input = (
    before => sub {
        my $line = shift;
        if ($line =~ /$start_delim/) {
            $toc_status = 'inside';
        } elsif ($line =~ /\A#{$min_hlvl}(#+) (.+)\Z/) {
            toc_add(@toc, $1, $2);
        }
    },
    inside => sub {
        my $line = shift;
        $toc_status = 'after' if ($line =~ /$end_delim/);
    },
    after => sub {
        my $line = shift;
        if ($line =~ /\A#{$min_hlvl}(#+) (.+)\Z/) {
            toc_add(@toc, $1, $2);
        }
    }
);
$parse_input{$toc_status}->($_) while (<$SOURCE>);

# Having a starting delimeter but no ending one causes the parser above to
# ignore everything from the starting delimeter to the end of file
if ($toc_status eq 'inside') {
    say 'ERROR: A starting delimeter was found but no ending delimeter';
    exit 1;
}

# newline required for Markdown to treat this as a comment
push @toc, "\n" . $end_delim if $opt_d;

unless ($opt_w) {
    close $SOURCE;
    say foreach @toc;
    exit 0;
}

# Option -w selected
my $tmp_file   = "/tmp/ghtocgen-$$";
open my $TMP, '>:utf8', $tmp_file or die $!;
seek $SOURCE, 0, 0;

$toc_status = 'before';             # possible values: before, inside, after
while (<$SOURCE>) {
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

close $SOURCE;
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
