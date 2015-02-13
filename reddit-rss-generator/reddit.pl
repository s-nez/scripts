#!/usr/bin/perl
use strict;
use warnings;
use feature 'say';
use File::Basename;
use File::Path 'make_path';
use File::Copy;
use IO::Prompt;
use Reddit::Client;
use constant URL_BASE => 'http://www.reddit.com';

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

sub verify_option {
    my ($option, $name) = @_;
    if (not defined $option or $option =~ /\A--?/) {
        say 'You need to specify a ', $name;
        print_help();
        exit 1;
    }
    return;
}

my $login;
my $subreddit;

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

my $config_dir      = $ENV{HOME} . '/.reddit/' . $login;
my $session_file    = $config_dir . '/session';
my $user_hash_file  = $config_dir . '/hash';
my $subreddits_file = $config_dir . '/subreddits';

make_path($config_dir) unless (-e $config_dir and -d $config_dir);

sub store_last_link {
    my ($link) = @_;
    my $last_item_id = $link->{name};

    if (not -e $subreddits_file) {
        open my $CONFIG, '>', $subreddits_file or die $!;
        say $CONFIG $subreddit, ' ', $last_item_id;
        close $CONFIG;
    } else {
        my $tmp_file = '/tmp/reddit-rss-generator-tmp';
        open my $TMP,    '>', $tmp_file        or die $!;
        open my $CONFIG, '<', $subreddits_file or die $!;

        while (<$CONFIG>) {
            last if m|\A$subreddit|;
            print $TMP $_;
        }
        say $TMP $subreddit, ' ', $last_item_id;
        print $TMP $_ while <$CONFIG>;

        close $TMP;
        close $CONFIG;
        move($tmp_file, $subreddits_file);
    }
}

sub get_last_link {
    open my $CONFIG, '<', $subreddits_file or die $!;
    my $link_id;
    while (<$CONFIG>) {
        if (m|\A$subreddit\s+(.+)|) {
            $link_id = $1;
            last;
        }
    }
    close $CONFIG;
    return $link_id;    # returning undef is fine
}

my $reddit = Reddit::Client->new(
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
    chomp(my $hash = <>);
    open my $UHF, '>', $user_hash_file or die $!;
    print $UHF $hash;
    close $UHF;
}

open my $UHF, '<', $user_hash_file or die $!;
my $user_hash = <$UHF>;
close $UHF;

my $links = $reddit->fetch_links(
    subreddit => $subreddit,
    before    => get_last_link(),
    limit     => 100
);

if (@{ $links->{items} }) {
    foreach my $item (@{ $links->{items} }) {
        my $url = $item->{permalink};
        say URL_BASE . $url . '.rss?feed=' . $user_hash . '&user=' . $login;
    }
    store_last_link($links->{items}->[0]);
} else {
    say 'There are no new items';
}
