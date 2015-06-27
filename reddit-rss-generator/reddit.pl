#!/usr/bin/perl
use strict;
use warnings;
use feature 'say';
use File::Basename;
use File::Path 'make_path';
use File::Copy;
use IO::Prompt;
use Reddit::Client;
use Getopt::Long;
use autodie;
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
      "    -a/--all - unconditionally fetch all links\n",
      "    -h/--help - display this help";
}

my ($login, $subreddit);
my ($fetch_all, $show_help) = (0, 0);
GetOptions(
    'u|user=s'      => \$login,
    's|subreddit=s' => \$subreddit,
    'a|all'         => \$fetch_all,
    'h|help'        => \$show_help
) or die "Error in command line arguments\n";
die "Too many arguments\n" if @ARGV;

if ($show_help or not defined $login or not defined $subreddit) {
    print_help();
    exit;
}

my $config_dir      = $ENV{HOME} . '/.reddit/' . $login;
my $session_file    = $config_dir . '/session';
my $user_hash_file  = $config_dir . '/hash';
my $subreddits_file = $config_dir . '/subreddits';

make_path($config_dir) unless -d $config_dir;

sub store_last_link {
    my ($link) = @_;
    my $last_item_id = $link->{name};

    if (not -e $subreddits_file) {
        open my $CONFIG, '>', $subreddits_file;
        say $CONFIG $subreddit, ' ', $last_item_id;
        close $CONFIG;
    } else {
        my $tmp_file = '/tmp/reddit-rss-generator-tmp';
        open my $TMP,    '>', $tmp_file;
        open my $CONFIG, '<', $subreddits_file;

        while (<$CONFIG>) {
            last if m/\A$subreddit/;
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
    open my $CONFIG, '<', $subreddits_file;
    my $link_id;
    while (<$CONFIG>) {
        if (/\A$subreddit\s+(.+)/) {
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
    open my $UHF, '>', $user_hash_file;
    print $UHF $hash;
    close $UHF;
}

open my $UHF, '<', $user_hash_file;
my $user_hash = <$UHF>;
close $UHF;

my $last_link = $fetch_all ? undef : get_last_link();
my $links = $reddit->fetch_links(
    subreddit => $subreddit,
    before    => $last_link,
    limit     => 100
);

if (@{ $links->{items} }) {
    foreach my $item (@{ $links->{items} }) {
        my $url = $item->{permalink};
        say URL_BASE . $url . '.rss?feed=' . $user_hash . '&user=' . $login;
    }
    store_last_link($links->{items}[0]);
} else {
    say 'There are no new items';
}
