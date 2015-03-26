#!/usr/bin/perl
# Copyright (C) 2014  Szymon Nieznański

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use feature 'say';
use File::Copy 'move';
use Clipboard;

#######################################################################
# User-configurable variables
#
# Batch file location
my $source = $ENV{HOME} . '/Remote/youtube';
#
# Downloads destination
my $dest_folder = $ENV{HOME} . '/Downloads/YouTube/';
#
# Filename pattern in youtube-dl -o format
my $file_pattern = '%(title)s.%(ext)s';
#
# End of user-configurable variables
#######################################################################

# Output file as passed to youtube-dl -o operation
my $destination = ($dest_folder . $file_pattern);

sub display_help {
    say 'Operations:
	download - download a video from specified address or from the batch file if no address specified
	clear - clean up videos not watched for a week from the download directory
	add - add the specified address to the batch file
	show - display addresses in the batch file
    modify - remove selected entries from the batch file
	remove - remove all entries from the batch file
	help - display this help';
}

# Ask the user for confirmation and return their answer
sub user_confirmed {
    print $_[0], '[y/n] ';
    my $answer = getc;
    return $answer eq 'y';
}

# Display contents of a file and its total line count
sub display_file {
    my ($filename) = @_;
    open my $FILE, '<', $filename or die "$filename:$!";
    my $lines = 0;
    while (<$FILE>) {
        print;
        ++$lines;
    }
    print while (<$FILE>);
    close $FILE;
    say 'Total: ', $lines, ' videos';
    return;
}

# Reduce file to size 0 without deleting it, used to clear the batch file
sub truncate_file {
    my ($filename) = @_;
    open my $FILE, '>', $filename or die "$filename:$!";
    truncate $FILE, 0;
    close $FILE;
}

# Add an address to the batch file
sub add {
    my ($address) = @_;
    unless (defined $address) {

        # Try to use clipboard contents if no address given
        chomp(my $link = Clipboard->paste);
        my $confirmation_message =
            "No address was specified, "
          . "the clipboard contains the following:\n"
          . $link
          . "\nDo you want to add it?";
        if (user_confirmed $confirmation_message) {
            $address = $link;
        }
    }
    die 'No address specified' unless defined $address;
    open my $FILE, '>>', $source or die $!;
    say $FILE $address;
    close $FILE;
}

# Remove files with access dates older than one week from the given directory
sub cleanup {
    my ($dir) = @_;
    opendir my $DH, $dir or die $!;
    while (readdir $DH) {
        my $full_path = $dir . '/' . $_;
        next if -d $full_path;                    # skip directories
        unlink $full_path if -A $full_path > 7;
    }
}

# Download video from the specified address or the batch file
sub download {
    my ($address) = @_;
    if (defined $address) {
        system "youtube-dl -o \'$destination\' \'$address\'";
    } else {
        system "youtube-dl -a \'$source\' -o \'$destination\'";
        truncate_file $source if $? == 0;
    }
}

# Review and remove batch file entries
sub modify {
    my ($filename) = @_;
    open my $FH, '<', $filename or die $!;
    print $., ': ', $_ while (<$FH>);
    print 'Entries to remove: ';
    my $to_remove = <>;
    chomp $to_remove;

    # Filter out non-number entries and sort the rest numerically
    my @entries = sort { $a <=> $b } grep { /\A\d+\Z/ } split ' ', $to_remove;
    return unless @entries;    # no entries, nothing to do

    seek $FH, 0, 0;            # go back to the beginning of file
    $FH->input_line_number(1); # make $. indicate the line ahead

    my $tmp_file = '/tmp/' . $$ . '-youtube.tmp';
    open my $TMP, '>', $tmp_file or die $!;

    foreach my $entry (@entries) {
        while (not eof $FH and $entry > $.) {
            print $TMP scalar <$FH>;
        }
        readline $FH if $entry == $.;    # skip the line if it matches an entry
    }
    print $TMP $_ while (<$FH>);         # write the rest of the file

    close($FH);
    close($TMP);
    move($tmp_file, $filename);
}

mkdir $dest_folder unless -d $dest_folder;

my $operation = shift;
unless (defined $operation) {
    say 'No arguments.';
    display_help;

} elsif ($operation eq 'download') {
    download shift;

} elsif ($operation eq 'clear') {
    cleanup $dest_folder;

} elsif ($operation eq 'add') {
    add shift;

} elsif ($operation eq 'show') {
    display_file $source;

} elsif ($operation eq 'remove') {
    truncate_file $source;

} elsif ($operation eq 'modify') {
    modify $source;

} elsif ($operation eq 'help') {
    say 'A command-line interface to YouTube (using youtube-dl).';
    display_help;

} else {
    say 'Unknown operation: ', $operation;
    display_help;
}
