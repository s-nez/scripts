#!/usr/bin/perl
use strict;
use warnings;
use feature 'say';
use IO::Prompt;
use Reddit::Client;

# Required to output UTF-8 characters correctly
binmode STDOUT, ":utf8";

sub print_help {
	say 'HELP!';
}

my $login;
my $subreddit;

sub verify_option {
	my ($option, $name) = @_;
	if (not defined $option or $option =~ /\A--?/) {
		say 'You need to specify a ', $name;
		print_help();
		exit 1;
	}
	return;
}

sub parse_args {
	while (@ARGV) {
		my $opt = shift @ARGV;
		if ($opt =~ /\A(?:-u)|(?:--user)\Z/) {
			$login = shift @ARGV;
			verify_option($login, 'username');
		} elsif ($opt =~ /\A(?:-s)|(?:--subreddit)\Z/) {
			$subreddit = shift @ARGV;
			verify_option($subreddit, 'subreddit');
			$subreddit = '/r/' . $subreddit;
		} else {
			die "Unrecognised option: $opt";
		}
	}
}

@ARGV or print_help and exit; # Only in Perl :D
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
