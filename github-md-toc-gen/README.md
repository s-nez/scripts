# Markdown Table Of Contents Generator
This scripts takes a markdown-formatted file and generates a table of contents
using the header levels. It also generates hyperlinks that work out-of-the-box
on GitHub.

## Usage
````
./toc-gen.pl [ -dw ] [ -t[:string] ] [ -s[:number] ] [ -e[:number] ] [ file ]
````
If run without options, the script will print a Table of Contents to STDOUT.

### -d
Makes the script surround the ToC with a pair of delimeters:
````
<!--TOC_START--->
<!--TOC_END--->
````
These are comments in Markdown, so they don't appear in the resulting document.
They are used to locate an existing ToC in a source file.

### -w
Write the ToC into the source file instead of STDOUT. This option needs the
start and end delimeters to be present in the source file, the ToC is going
to be inserted between them, keeping the rest of the file intact. If used
without the **-d** option, the delimeters are going to be removed from the
source file.

### -s[:number]
Specifies the starting heading level to be included in the ToC (default: 1).
For a heading to be a part of the Table Of Contents, it's heading level needs
to be higher than this number.

#### Example:
file.md:
````
# One
## Two
### Three
#### Four
````
````
./toc-gen.pl -s 2 file.md
````
Only "Three" and "Four" are going to be included in the ToC, because their
heading levels are higher than 2.

### -e[:number]
Analogous to **-s**, this option specifies the ending heading level to be
included in the ToC (default: 4). Any headings with a level higher than this
number are going to be skipped.

### -t[:string]
Add a custom title to the Table Of Contents. The title is going to be heading
one level higher than the minimum (**-s**), so 2 by default.

#### Example:
````
./toc-gen.pl -t "Table Of Contents" file.md
````
The resulting ToC will begin with a following line:
````
## Table Of Contents
````
There is no title by default.

**NOTE:** The script assumes UTF8 file encoding.
