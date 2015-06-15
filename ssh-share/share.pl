#!/usr/bin/env perl 
use strict;
use warnings;
use autodie;
use Net::OpenSSH;

#######################################################################
# User-configurable variables
#
# Location of the configuration file
my $CONF = './ssh-share.conf';
#
# End of user-configurable variables
#######################################################################

my $target = shift;
defined $target or die "You need to specify a target\n";
@ARGV or die "No files to upload\n";

my $target_host;
open my $FH, '<', $CONF;
while (<$FH>) {
    my ($entry, $host) = split;
    if ($entry eq $target) {
        $target_host = $host;
        last;
    }
}
close $FH;
defined $target_host or die "Entry '$target' not found in config\n";

my ($host, $dir) = split ':', $target_host;
defined $host and defined $dir or die "Invalid entry: $target_host\n";

my $ssh = Net::OpenSSH->new($host);
$ssh->scp_put({glob => 1, recursive => 1}, @ARGV, $dir);
