# fedbotrandom
Simple bot to post a random line from a text file to a Mastodon instance.

(c) 2018-2022 Kelson Vibber. https://codeberg.org/kvibber/fedbotrandom

Give it an access token and a text file with items to post, and it will pick a random line
from the file and post that line to your Mastodon account. (I recommend https://botsin.space
which is intended to be used by bots. Be sure to check your instance's policy toward bots
before you use this!)

For multi-line posts, indent the second line and beyond. Use any number of spaces or tabs
you want! It's designed to be flexible!

For example:

```
Oh no!
  Carmen Sandiego has stolen your sample text!
Help, I'm trapped in a code factory!
```

That's two items. The first one will be split across two lines in one post.

You can separate items with blank lines, but you don't have to. If you want
a blank line in a multiline post, just indent it along with the rest of that item.

Optionally you can specify a second text file as a queue of new items. It will
post from the queue until it runs out, adding each item to the main list as it goes.
If the second file is missing or empty, it will return to picking random items from
the main list.

## Configuration

You'll need an access token from the Mastodon instance you want to post to,
which you can get by creating an app in your Mastodon preferences at
Preferences/Development/Your Applications

For example: https://botsin.space/settings/applications

The application you create must have at LEAST write:statuses permission.

Add your instance's hostname and the access token to fedbotrandom.config. If you
want, you can also set the post source files in the config, or you can set them
to the command line. You can also set up several config files so you can run more
than one bot using the same script.

```
fedbotrandom.config:

INSTANCE_HOST: botsin.space (required)
API_ACCESS_TOKEN: your_access_token (required)
LIST_FILE: quotes.txt (optional)
NEW_ITEMS_FILE: newquotes.txt (optional)
```

## Usage

Call with no parameters and it will load everything from fedbotrandom.config,
posting one random line from LIST_FILE.
```
     fedbotrandom.pl
```
Call with the name of an alternate configuration file.
```
     fedbotrandom.pl myalternate.config
```
     
Call with a config file and an alternate source file for the random posts:
```
     fedbotrandom.pl myalternate.config quotes.txt
```
      
Call with a config file, alternate list, and alternate new-item lists.
```
     fedbotrandom.pl myalternate.config quotes.txt newquotes.txt
```

To run it regularly, just schedule it as a cron job.

## Why Perl and not something more modern? Why text files and not a database?

To keep it simple. This way I can put the script and text files on any *nix
system without worrying about which languages or databases are available,
or having to install a runtime, and I can just run it from cron. No sense
building a scheduler when one already exists, right?
