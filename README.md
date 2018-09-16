# fedbotrandom
Simple bot to post a random line from a text file to Mastodon.
By Kelson Vibber. https://github.com/kvibber/fedbotrandom

Give it an access token and a text file with items to post, and it will pick a random line from the file and post that line to your Mastodon account.

Optionally you can specify a second text file as a queue of new items. It will
post from the queue until it runs out, adding each item to the main list as it goes. If the second file is missing or empty, it will return to picking random items from the main list

For now, configuration is done in the script itself.
Add the hostname of your instance (ex. botsin.space) and the access token,
which you can get by creating an app in your Mastodon preferences at
Preferences/Development/Your Applications
For example: https://botsin.space/settings/applications

Call the script to post one random line from the text file:
`     fedbotrandom.pl quotes.txt`

Or to post the first line from newquotes.txt, then move that line
to quotes.txt for future posts:
`     fedbotrandom.pl quotes.txt newquotes.txt`
     
To run it regularly, you can schedule it as a cron job.


TODO:
I'm deliberately not making this complicated, but I will probably add:
- multiline posts.
- external config file.
