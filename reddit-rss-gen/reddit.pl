#!/usr/bin/perl
use strict;
use warnings;
use feature 'say';
use File::Basename;
use IO::Prompt;
use Reddit::Client;

# Required to output UTF-8 characters correctly
binmode STDOUT, ":utf8";

sub print_help {
	my $script_name = basename($0);
	say "Usage:\n",
	"$script_name -u [USER] -s [SUBREDDIT]\n\n",
	"Options:\n",
	"    -u/--user - your Reddit username\n",
	"    -s/--subreddit - the name of the target subreddit\n",
	"    -h/--help - display this help";
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
		} elsif ($opt =~ /\A(?:-h)|(?:--help)\Z/) {
			print_help();
			exit 0;
		} else {
			die "Unrecognised option: $opt";
		}
	}
}

parse_args();
defined $login and defined $subreddit or print_help and exit;

my $config_dir = $ENV{HOME} . '/.reddit/' . $login;
my $session_file = $config_dir . '/session';
my $user_hash_file = $config_dir . '/hash';

mkdir $config_dir unless (-e $config_dir and -d $config_dir);

my $reddit       = Reddit::Client->new(
	session_file => $session_file,
	user_agent   => 'Hue/1.0',
);

unless ($reddit->is_logged_in) {
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

my $links = $reddit->fetch_links(subreddit => $subreddit);
foreach my $item (@{$links->{items}}) {
	say $item->{url} . '.rss?feed=' . $user_hash . '&user=' . $login;
}
