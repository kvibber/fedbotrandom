#!/usr/bin/perl
# Super-simple bot that picks a random line from a text file and posts it to
# an account on Mastodon.
#
# Version 0.9 - 2022-01-09
#
# Configure by adding your instance hostname and access token here.
# Call with the text filename as the parameter
#      fedbotrandom.pl quotes.txt
#
# Optionally you can list a second file that will be processed as a queue for
# new items, which will then be appended to the main list.
#      fedbotrandom.pl quotes.txt newquotes.txt
#
# To run regularly, just schedule it as a cron job.
# By Kelson Vibber, https://codeberg.org/kvibber/fedbotrandom

use strict;
use warnings;
use LWP;
  
# Configuration. Get your access token by creating an app in your Mastodon
# preferences at Preferences/Development/Your Applications.
# It needs at least write:statuses permission.
# For example, https://botsin.space/settings/applications
my $INSTANCE_HOST='botsin.space';
my $API_ACCESS_TOKEN='your_access_token';

my $content = "";

# Get the filenames
my $listSource = $ARGV[0];
my $newList = $ARGV[1];

if (!defined $listSource) {
	die "No source file specified.";
}

my @queue;
my $fromQueue = 0;

# If the new list exists, read the first item from it.
if ( defined $newList && -f $newList) {
	open newItems, "<", $newList;
	@queue = <newItems>;
	close newItems;
	if (scalar @queue > 0) {
		# Get the first item with actual content.
		while($content eq "" && scalar @queue > 0) {
			$content = shift(@queue);
			$content =~ s/^\s+|\s+$//g;
		}
		if ($content ne "") {
		
			# If we found something, append following indented lines.
			while (my $nextLine = shift(@queue)) {
				if ($nextLine =~ /^\s/) {
					$nextLine =~ s/^\s+|\s+$//g;
					$content .= "\n" . $nextLine;
				} else {
					unshift (@queue, $nextLine);
					last;
				}
			}
		
			$fromQueue = 1;
		}
	}

}


# If we didn't get anything from the new-item queue, pull randomly from the main list.
if ($content eq "") {

	# Read the list from the file.
	if (open listFile,  "<", $listSource) {
		my @list = <listFile>;
		close listFile;

		# Randomly select an element from the list
		my $loopsRemaining = 10;
		while($content eq "" && $loopsRemaining > 0 && scalar @list > 0) {
			my $index = int(rand(scalar @list));
			
			# Don't start with an indented line
			while ($list[$index] =~ /^\s/ && $index < scalar @list - 1) {
				$index++;
			}
			
			$content = $list[$index];
			$content =~ s/^\s+|\s+$//g;
			
			# If we found something, append following indented lines.
			while ($content ne "" && $index < scalar @list - 1) {
				$index++;
				my $nextLine = $list[$index];
				if ($nextLine =~ /^\s/) {
					$nextLine =~ s/^\s+|\s+$//g;
					$content .= "\n" . $nextLine;
				} else {
					last;
				}
			}
			
			$loopsRemaining--;
		}
	}
}

if ($content eq "") {
	die ("No content found.");
}

my $url = "https://$INSTANCE_HOST/api/v1/statuses?access_token=$API_ACCESS_TOKEN";

print "Posting [$content] to $INSTANCE_HOST\n";

my $browser = LWP::UserAgent->new;
my $response = $browser->post( $url,
   [
     status => $content, 
     visibility => 'unlisted'
   ],
);

if ($response->is_success) {

	# If we got something from the new list, we now need to do two things:
	# append it to the randomizer list and remove it from the queue.
	if ($fromQueue) {
		open newItems, ">", $newList;
		foreach my $item (@queue) {
			print newItems $item;
		}
		close newItems;

		# Append it to the regular list, with the indentations put back
		open listFile,  ">>", $listSource;
		$content =~ s/\n/\n  /g;
		print listFile "\n$content";
		close listFile;
	}

	print "Done!\n";
}
else {
	print STDERR "Failed: " , $response->status_line, "\n";
}
