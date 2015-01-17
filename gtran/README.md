# gtran
A front-end to web-based translation services using libtranslate, designed to be invoked with a keyboard shortcut.

# Dependencies
* [libtranslate](http://www.nongnu.org/libtranslate/)
* xclip
* libnotify
* zenity

On Fedora:

    # yum install libtranslate xclip libnotify zenity
# Usage
GTran takes two mandatory command line arguments - the source language and the target language - as two-letter language codes. For example, to translate from English to Polish:
   
    $ gtran en pl
A text input box will appear, by default it will be populated with clipboard contents.
