# youtube
A wrapper script for youtube-dl. Allows for simple queueing, downloading and cleanup of YouTube videos.

# Dependencies
* [youtube-dl](http://rg3.github.io/youtube-dl/)
* [Clipboard](https://metacpan.org/pod/Clipboard)

On Fedora:

    # yum install perl-Clipboard youtube-dl

# Installation and configuration
The script can be run from anywhere, though you may want to put it somewhere in your $PATH for convenient use.

Configuration boils down to three variables at the beginning of the script. The defaults are fine to leave as is, you only need to change anything if you want to personalise any of the settings.

**source** - full path to the file that will hold your download queue (default: _$HOME/Remote/youtube_)

**dest_folder** - full path to the folder where the videos are going to be put (default: _$HOME/Downloads/YouTube_)

**file_pattern** - a string accepted by youtube-dl -o paramter (default: _%(title)s.%(ext)s_)

# Usage
The script accepts any of the following parameters:

**download** - downloads all videos from the download queue, if a YouTube address is specified, then the video from that address is downloaded without being added to the queue.
For example, this will download all videos from the queue:

    $ youtube.pl download
This will download the [Big Buck Bunny](https://www.youtube.com/watch?v=YE7VzlLtp-4) video:

    $ youtube.pl download 'https://www.youtube.com/watch?v=YE7VzlLtp-4'
    
**clear** - cleans up the download directory. This option makes the script look through the download directory and delete any file with access date older than a week.

**add** - adds the specified address to your download queue. If no address given, the script will attempt to use clipboard contents as the address and will prompt the user to confirm.

**show** - displays the download queue along with the total count of videos.

**remove**- clears the download queue. This remove all entries in the batch file containing the queue and leave it empty.

**help** - display a short summary of options.
