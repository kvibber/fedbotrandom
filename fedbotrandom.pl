#!/usr/bin/perl
# Super-simple bot that picks a random line from a text file and posts it to
# an account on Mastodon.
#
# Configure by adding your instance hostname and access token here.
# Call with the text filename as the parameter
#      fedbotrandom.pl quotes.txt
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

# Read the list from the file given on the command line.
my $listSource = $ARGV[0];
open listFile, $listSource;
my @list = <listFile>;
close listFile;

# Randomly select an element from the list
my $content = "";
my $loopsRemaining = 10;
while($content eq "" && $loopsRemaining > 0) {
	my $index = int(rand(scalar @list));
	$content = $list[$index];
	$content =~ s/^\s+|\s+$//g;
	$loopsRemaining--;
}

my $url = "https://$INSTANCE_HOST/api/v1/statuses?access_token=$API_ACCESS_TOKEN";

print "Posting $content to $INSTANCE_HOST\n";

my $browser = LWP::UserAgent->new;
my $response = $browser->post( $url,
   [
     status => $content, 
     visibility => 'unlisted'
   ],
);
