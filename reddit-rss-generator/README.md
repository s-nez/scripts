# Reddit RSS Generator
This script generates URLs to comment feeds on private subreddits.

# Dependencies
* [IO::Prompt](https://metacpan.org/pod/IO::Prompt)
* [JSON](https://metacpan.org/pod/JSON)
* [URI::Encode](https://metacpan.org/pod/URI::Encode)
* [Reddit::Client](https://metacpan.org/pod/Reddit::Client)

On Fedora (installs all required modules except Reddit::Client):

    # yum install perl-IO-Prompt perl-JSON perl-URI-Encode

# Configuration
The script creates a configuration directory inside your home folder (~/.reddit). It is used to store session files and authorisation hashes.

**NOTE:** The script does not store your password in any way.

# Usage
You need to provide your username and the name of a subreddit to the script. For example, if you want to fetch comment feeds from __r/mysubreddit__ and your Reddit username is __john__:

    reddit.pl -u john -s mysubreddit

On first run (or if the configuration got deleted) you will be prompted for your password and authorisation hash. The hash can be found in any of the URLs from [here](https://www.reddit.com/prefs/feeds). It's the sequence between __feed=__ and __&user__. For example, if your front page feed URL looks like this:

http://w<b></b>ww.reddit.com/.rss?feed=<b>6209378f6de16261f5d9230d26e6412e</b>&user=john

then your authorisation hash is: 6209378f6de16261f5d9230d26e6412e.
