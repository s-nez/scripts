#!/usr/bin/perl
use strict;
use warnings;
use feature 'say';
use IO::Prompt;
use Reddit::Client;

# Required to output UTF-8 characters correctly
binmode STDOUT, ":utf8";

my $config_dir = $ENV{HOME} . "/.reddit";
my $session_file = $config_dir . '/session';
my $user_hash_file = $config_dir . '/hash';
my $username_file = $config_dir . '/user';

mkdir $config_dir unless (-e $config_dir and -d $config_dir);

my $reddit       = Reddit::Client->new(session_file => $session_file);

unless ($reddit->is_logged_in) {
	print "Login: ";
	chomp (my $login = <>);
	my $password = prompt('Password: ', -e => '*');
	$reddit->login($login, $password);
	$reddit->save_session();

	open my $UF, '>', $username_file;
	print $UF $login;
	close $UF;
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

open my $UF, '<', $username_file or die $!;
my $username = <$UF>;
close $UF;

my $links = $reddit->fetch_links(subreddit => '/r/slimak');
foreach (@{$links->{items}}) {
	say $_->{url} . '.rss?feed=' . $user_hash . '&user=' . $username;
}
