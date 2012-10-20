#!/usr/bin/perl
################################################################################
# 
# A simple script which generates a unique passphrase by taking several random 
# words from the text of books that are on Project Gutenberg
# (http://www.gutenberg.org) to generate a single easy-to-remember passphrase
# Inspired by XKCD Comic #936: http://xkcd.com/936/
# 
#
# Copyright (C) 2012 Computer Science Club at DC & UOIT
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
################################################################################
use warnings;
use DBI();
use feature qw(say);
use Tie::File;
use File::CountLines qw(count_lines);


# Database access
my $db_user = "";
my $db_pass = "";
my $db_name = "";

# The book that you wish to use the text from, download the text of a book
# from Project Gutenberg (http://www.gutenberg.org)
my $book = "";
my $book_lines = 0;

# Maximum and minimum password length, MAX LENGTH IN DATABASE IS 64 CHARACTERS
my $maxlength = 16;
my $minlength = 12;
my $randnum = 0;
my $passphrase = "";
my $line = "";
my @words = ();
my $word = "";

if ($book eq "" && @ARGV < 1)
{
    die "You must provide the path & name of a book to use as a text source,\n".
	"Download a book from Project Gutenberg (http://www.gutenberg.org) in text format";
}
elsif (@ARGV >= 1)
{
	$book = $ARGV[0];
}

# Clean up the text, remove the project gutenberg disclaimers/legal info
# by removing the first and last 400 lines from the text
if(-e $book)
{
    $idx = 1;
    $idx2 = 500;  # Starts 500 lines from the end of the book
	tie @file_lines, 'Tie::File', $book or die;
	$book_lines = count_lines($book);
    
	# If it is a project gutenburg file remove the header and footer of the book
	if ($file_lines[0] =~ /Project\s*Gutenberg/)
	{
        # Lines from header to remove
		until ($file_lines[$idx] =~ /\*\*\*\s*START\s*OF.*PROJECT\s*GUTENBERG/
                || $file_lines[$idx] =~ /\*END\*\s*THE\s*SMALL\s*PRINT\!/)
		{
            $idx++;
		}
        $idx++;
        
        # Lines from footer to remove
        until ($file_lines[$book_lines - $idx2] =~ /End\sof.*Project\s*Gutenberg/ 
                || $file_lines[$book_lines - $idx2] =~ /\*\*\*\s*END\s*OF.*PROJECT\s*GUTENBERG/
                || $file_lines[$book_lines - $idx2] =~ /\*\*\*\s*START:\s*FULL\s*LICENSE/)
        {
            $idx2--;
        }
        
        # Remove the header and footer
        for ($i = 0; $i < $idx; $i++)
        {
            shift @file_lines;
        }
        for ($j = 0; $j < $idx2; $j++)
        {
            pop @file_lines;
        }
		$book_lines -= ($idx + $idx2);
	}
}
else
{
	die "$book does not exist, edit this script to configure which book to use!";
}


# Select random lines of text and random words to generate a
# passphrase that meets constraints
while ()
{
	# Select a random line and remove words with less than 4 characters
	$randnum = int(rand($book_lines));
	$line = $file_lines[$randnum];
	# FUCK PUNCTUATION AND FUCK CONTROL CHARACTERS
	$line =~ s/[\t\n\r]//g;
	$line =~ s/[\!\"\#\$\%\&\'\(\)\*\+\,\-\.\/\:\;\<\=\>\?\@\[\]\^\_\`\{\|\}\~\d\\]//g;
	# Remove all words < 5 characters in length
	$line =~ s/^[\w]{1,4}\s/ /;
	$line =~ s/\s[\w]{1,4}$/ /;
	while ($line =~ s/\s[\w]{1,4}\s/ /) {} ;
	@words = split(/ /, $line);
	
	if (@words)
	{ 
		$passphrase .= lc($words[int(rand($#words + 1))]);
	}
	
	if (length($passphrase) >= $minlength && length($passphrase) <= $maxlength)
	{
		last;
	}
	elsif (length($passphrase) > $maxlength)
	{
		$passphrase = "";
	}
}


# close the text file
untie @file_lines or die "$!";

# Connect to the database.
my $dbh = DBI->connect( "DBI:mysql:database=${db_name};host=localhost",
						$db_user, $db_pass, {'RaiseError' => 1});

# INSERT the passphrase into the passphrases table
$dbh->do("INSERT INTO passphrases VALUES (" . $dbh->quote($passphrase) . ", " . 'CURDATE()' . ", " . 'NULL' . ")");

# Display the passphrase
say "\nPASSPHRASE: " . $passphrase . "\n";
	
# Disconnect from the database.
$dbh->disconnect();
