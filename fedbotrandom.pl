#!/usr/bin/perl
# Super-simple bot that picks a random line from a text file and posts it to
# an account on Mastodon.
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
# By Kelson Vibber, https://github.com/kvibber/fedbotrandom

use strict;
use warnings;
use LWP;
  
# Configuration. Get your access token by creating an app in your Mastodon
# preferences at Preferences/Development/Your Applications
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

# If the new list exists, read the first item from it.
if ( defined $newList && -f $newList) {
	open newItems, "<", $newList;
	my @list = <newItems>;
	close newItems;
	if (scalar @list > 0) {
		# Get the first item with actual content.
		while($content eq "" && scalar @list > 0) {
			$content = shift(@list);
			$content =~ s/^\s+|\s+$//g;
		}
		# If we got something, we now need to do two things:
		# append it to the randomizer list and remove it from the queue.
		if ($content ne "") {

			open newItems, ">", $newList;
			foreach my $item (@list) {
				print newItems $item;
			}
			close newItems;

			# Append it to the regular list.
			open listFile,  ">>", $listSource;
			print listFile "\n$content";
			close listFile;
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
			$content = $list[$index];
			$content =~ s/^\s+|\s+$//g;
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
	print "Done!\n";
}
else {
	print STDERR "Failed: " , $response->status_line, "\n";
}
