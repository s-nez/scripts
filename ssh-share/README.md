# SSH Uploader
This script allows the user to create aliases to SSH locations (user,
hostname and remote directory combinations) and upload files to
these predefined locations in a simple way.

## Dependencies
* [Net::OpenSSH](https://metacpan.org/pod/Net::OpenSSH)

On Fedora:
```
# dnf install perl-Net-OpenSSH
```

On Debian/Ubuntu:
```
# apt-get install libnet-openssh-perl
```

## Config format
The configuration file can be specified by editing the **$CONF** variable
at the beginning of the script. The format is as follows:
```
alias1 user1@host1:dir1
alias2 user2@host2:dir2
...
```

The alias can be separated from the remote location by any amount of
whitespace. 

## Usage
```
./share.pl [alias] [files]
```

For example, with the example config:
```
./share.pl alias1 some_file other_file up*
```
This will upload some\_file, other\_file and all filed beginning with "up"
to **dir1** at **host1**, logging in as **user1**. You may need to provide
a password for the user or an ssh key, depending on your ssh configuration.
