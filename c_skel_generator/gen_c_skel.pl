#!/usr/bin/perl
use strict;
use warnings;
use feature qw(say);
use autodie;

die "You need to specify at least one filename\n" unless @ARGV;

foreach my $header_fname (@ARGV) {
    next unless $header_fname =~ /\A(.*)\.h(pp)?\z/;

    my $c_skel_fname = "$1.c" . ($2 // '');
    open my $FH_C_SKEL, '>', $c_skel_fname;
    say $FH_C_SKEL qq[#include "$header_fname"\n];

    open my $FH_HEADER, '<', $header_fname;
    my $in_mline_comment = 0;

    while (<$FH_HEADER>) {
        next if /\A(?:#|\s*\z)/;    # skip preprocessor directives and empty lines
        s{//.*$}{};                 # remove // comments
        s{/\*.*?\*/}{}g;            # remove /*comments*/ contained in a single line

        if (not $in_mline_comment) {
            $in_mline_comment = s{/\*.*\Z}{};
        }
        else {
            s{\A .*? (?: (\*/) | \Z )}{}x;
            $in_mline_comment = !$1;
        }

        s[\)\K;][ {\n\n}\n]g;
        print $FH_C_SKEL $_;
    }

    close $FH_C_SKEL;
    close $FH_HEADER;

    say "$c_skel_fname written based on $header_fname";
}
