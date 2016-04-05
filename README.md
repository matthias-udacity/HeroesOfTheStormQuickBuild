HeroesOfTheStormQuickBuild
==========================

HeroesOfTheStormQuickBuild is an app for iOS that helps to quickly find the most popular talent build for a particular hero in [Heroes of the Storm](http://us.battle.net/heroes/en/) using data from [HOTS Logs](http://www.hotslogs.com).

Features
--------

When started, the app displays a list of heroes:

![Heroes List](https://github.com/matthias-udacity/HeroesOfTheStormQuickBuild/raw/master/Screenshots/HeroesList.png)

When a hero is selected, the app displays the most popular talent build for the selected hero:

![Talent Build](https://github.com/matthias-udacity/HeroesOfTheStormQuickBuild/raw/master/Screenshots/TalentBuild.png)

Additional Features
-------------------

Once data has been fetched from the HOTS Logs website, it is persisted using CoreData. The app will display the heroes list and talent builds (as well as the corresponding icons) even when internet connectivity is unavailable if they have previously been loaded.

Using the refresh button on the hero list or talent build screen updates the screen with the most recent data from HOTS Logs.

Network activity is indicated using the standard iOS network indicator.

Building the app
----------------

The app has no additional library dependencies, so the Xcode probject should build as is.
