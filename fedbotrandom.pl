#!/usr/bin/perl
# Super-simple bot that picks a random line from a text file and posts it to
# an account on Mastodon. An optional second file can be used for new items
# that you want to post as they are added.
#
# Version 1.0 - 2022-04-03
#
# Configure by adding your instance hostname and access token in
# fedbotrandom.config. You can set the source files in the config
# or add them to the command line. You can also specify a different
# config file so you can use the same copy of fedbotrandom.pl to
# post to more than one account.
#
# INSTANCE_HOST: botsin.space (required)
# API_ACCESS_TOKEN: your_access_token (required)
# LIST_FILE: quotes.txt (optional)
# NEW_ITEMS_FILE: newquotes.txt (optional)
#
# Call with no parameters and it will load everything from fedbotrandom.config.
#      fedbotrandom.pl
#
# Call with the name of a configuration file.
#      fedbotrandom.pl myalternate.config
#
# Call with a config file and a list file.
#      fedbotrandom.pl myalternate.config quotes.txt
#
# Call with a config file, list, and a source for new items.
#      fedbotrandom.pl myalternate.config quotes.txt newquotes.txt
#
# To run regularly, just schedule it as a cron job.
# By Kelson Vibber, https://codeberg.org/kvibber/fedbotrandom

use strict;
use warnings;
use LWP;

# Load config file
my $configPath = $ARGV[0] || 'fedbot.config';
my %CONFIG;
open configFile, '<', $configPath || die "Cannot open configuration at $configPath";
my @lines = <configFile>;
close configFile;
foreach my $configLine(@lines) {
	if ($configLine =~ /^\s*([A-Za-z0-9_]+)\s*:\s*(.*)\s*$/) {
		$CONFIG{$1}=$2;
	}
}
# Override text files from command line
if (defined $ARGV[1]) {
	$CONFIG{'LIST_FILE'} = $ARGV[1];
}
if (defined $ARGV[2]) {
	$CONFIG{'NEW_ITEMS_FILE'} = $ARGV[2];
}

# Required config
if (!exists $CONFIG{'INSTANCE_HOST'}) {
	die "Please set INSTANCE_HOST to the target Mastodon instance, for example botsin.space";
}
if (!exists $CONFIG{'API_ACCESS_TOKEN'}) {
	die "Please set API_ACCESS_TOKEN in the config file.";
}
if (!exists $CONFIG{'LIST_FILE'}) {
	die "You can set LIST_FILE in the config or add the source filename on the command line.";
}

##################################################
my $content = "";
my @queue;
my $fromQueue = 0;

# If the new list exists, read the first item from it.
if ( exists $CONFIG{'NEW_ITEMS_FILE'} && -f $CONFIG{'NEW_ITEMS_FILE'} ) {
	open newItems, "<", $CONFIG{'NEW_ITEMS_FILE'} ;
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
	if (open listFile,  "<", $CONFIG{'LIST_FILE'}) {
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

my $url = "https://${CONFIG{'INSTANCE_HOST'}}/api/v1/statuses?access_token=${CONFIG{'API_ACCESS_TOKEN'}}";

print "Posting [$content] to $CONFIG{'INSTANCE_HOST'}\n";

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
		open newItems, ">", $CONFIG{'NEW_ITEMS_FILE'} ;
		foreach my $item (@queue) {
			print newItems $item;
		}
		close newItems;

		# Append it to the regular list, with the indentations put back
		open listFile,  ">>", $CONFIG{'LIST_FILE'};
		$content =~ s/\n/\n  /g;
		print listFile "\n$content";
		close listFile;
	}

	print "Done!\n";
}
else {
	print STDERR "Failed: " , $response->status_line, "\n";
}
