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
# Filename pattern in  youtube-dl -o format
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

# Download a video from the specified address or the batch file
sub download {
    my ($address) = @_;
    if (defined $address) {
        system "youtube-dl -o \'$destination\' \'$address\'";
    } else {
        system "youtube-dl -a \'$source\' -o \'$destination\'";
        truncate_file $source if $? == 0;
    }
}

mkdir $dest_folder unless -d $dest_folder;

unless (@ARGV) {
    say 'No arguments.';
    display_help;
} elsif ($ARGV[0] eq 'download') {
    download($ARGV[1]);
} elsif ($ARGV[0] eq 'clear') {
    cleanup $dest_folder;
} elsif ($ARGV[0] eq 'add') {
    add $ARGV[1];
} elsif ($ARGV[0] eq 'show') {
    display_file $source;
} elsif ($ARGV[0] eq 'remove') {
    truncate_file $source;
} elsif ($ARGV[0] eq 'help') {
    say 'A command-line interface to YouTube (using youtube-dl).';
    display_help;
} else {
    say 'Unknown operation: ', $ARGV[0];
    display_help;
}
