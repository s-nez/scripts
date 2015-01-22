#!/usr/bin/perl
use strict;
use warnings;
use feature 'say';
use IO::Prompt;
use Reddit::Client;

# Required to output UTF-8 characters correctly
binmode STDOUT, ":utf8";

my $login;
my $subreddit;

sub parse_args {
	while (@ARGV) {
		my $opt = shift @ARGV;
		if ($opt =~ /\A(?:-u)|(?:--user)\Z/) {
			$login = shift @ARGV;
		} elsif ($opt =~ /\A(?:-s)|(?:--subreddit)\Z/) {
			$subreddit = '/r/' . shift @ARGV;
		} else {
			die "Unrecognised option: $opt";
		}
	}
}

parse_args();

my $config_dir = $ENV{HOME} . '/.reddit/' . $login;
my $session_file = $config_dir . '/session';
my $user_hash_file = $config_dir . '/hash';

mkdir $config_dir unless (-e $config_dir and -d $config_dir);

my $reddit       = Reddit::Client->new(
	session_file => $session_file,
	user_agent   => 'Hue/1.0',
);

unless ($reddit->is_logged_in) {
	print "Login: ";
	chomp ($login = <>) unless length $login;
	my $password = prompt('Password: ', -e => '*');
	$reddit->login($login, $password);
	$reddit->save_session();
}

unless (-e $user_hash_file) {
	print 'User authorisation hash: ';
	chomp (my $hash = <>);
	open my $UHF, '>', $user_hash_file or die $!;
	print $UHF $hash;
	close $UHF;
}

open my $UHF, '<', $user_hash_file or die $!;
my $user_hash = <$UHF>;
close $UHF;

my $links = $reddit->fetch_links(subreddit => '/r/slimak');
foreach (@{$links->{items}}) {
	say $_->{url} . '.rss?feed=' . $user_hash . '&user=' . $login;
}
