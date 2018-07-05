# Greenpeace Planet 4

 [![CircleCI](https://circleci.com/gh/greenpeace/planet4-base/tree/develop.svg?style=shield)](https://circleci.com/gh/greenpeace/planet4-docker/tree/develop)

Testing.

This project provides the base for all Planet 4 sites.

To create a new project, that is powered by Planet 4, fork this repository.

## Prerequisite

-   You will need to have PHP 7 (or higher) and composer available on your system.
-   You will need git installed
-   You will need to have wp-cli installed and tested
-   You will also need mysql or mariadb installed as well.

## Installation
All dependencies should be managed by [Composer](http://getcomposer.org).

The same repository handles all the different Planet4 sites. This happens by having
- everything common in the /composer.json file
- everything site specific in a subdirectory app/project/site/composer.json file
(where project is the name of the Google Cloud Project and "site" is one of "develop", "staging") 

The composer plugin [composer merge](https://packagist.org/packages/wikimedia/composer-merge-plugin) handles the combining of the two composer.json files 

To tell composer which file to use, the first command you need to run is the following:
```
composer config extra.merge-plugin.require "app/planet4-gp-greece/production/composer.json"

```
(replacing `planet4-gp-greece/production` with whatever is applicable for the site you are building)

Then, install all required dependencies with one simple command:
```
composer install
```

If you want to add more dependencies to this project, you should also always
add them to the composer file. No manual copying of plugins or themes should be
necessary and any time.

## Configuration
You need to create a [Wordpress command line](http://wp-cli.org/) configuration file.
You can do that by copying the default one:
```
cp wp-cli.yml.default wp-cli.yml
```

This file is not tracked by default since it contains the complete configuration of
your Wordpress instance such as your database user passwod. When you need to change
the database configuration, the title or the URL of this
installation, please edit `wp-cli.yml`.
```
path: public

core config:
  dbuser: root
  dbpass: root
  dbname: wordpress

core install:
  title: Sample Planet 4 website
  url: http://test.planet4.dev
  admin_user: admin
  admin_email: admin@example.com

theme activate:
  - planet4-master-theme
```

NOTE: your website will be installed on the subdirectory "public" of the current
directory. Make sure that the "url" in the above configuration points to the
directory "public" so that wordpress sets up its live_site configurations correctly.

## Database setup
Before we can initialize the installation, make sure you did create the database
that is configured inside the configuration file. This can be easily done with this
command:
```
echo "CREATE DATABASE wordpress;" | mysql
```
It might be necessary to pass a username (`-u`) and a password (`-p`) to the
mysql command.
More information about this is available in the man page of `mysql` or
[online](https://dev.mysql.com/doc/refman/5.7/en/mysql-command-options.html).


## Install and active plugins and themes
After the database is created, the new Wordpress installation is installed with
one simple composer command:
```
composer run-script site-install
```

This will perform multiple steps:
-   Create a public directy and copy the Wordpress core in it
-   Create a `wp-config.php` file with default values from the `wp-cli.yml`.
-   Create the initial database structure and insert the default data
-   Copy themes and plugins listed as dependencies in `composer.json`.
-   Activate all the plugins listed as dependencies.
-   Activate the theme that is configured inside the `wp-cli.yml`

## Updating
In case a new version of the Wordpress core (a theme or plugin) is published and
you can update your base site by changing the version in `composer.json` and/or
running the update:
```
composer update
composer run-script site-update
```

This will perform multiple steps:
-   Fetch the new versions and dependencies
-   Merge the new wordpress core in the public directory without deleting your added files
-   Copy all the themes and plugins
-   Run Wordpress core database udpates if any
-   Deactivate and reactivate all the plugins

## Installing an alternate theme
Themes should never be changed inside the web front-end.

_Please note that only the themes that in greenpeace composer repository will be
available by default. You will need to add another repository if it is not a
supported theme_

This would make it impossible to have an automated installation that can be
re-applied whenever needed. To change the theme add the dependency to the
`composer.json` file.
```
"require": {
    ...
    "greenpeace/planet4-another-theme": "4.7.2",
    ...
}
```

Then you need to change the related line inside the `wp-cli.yml`.
```
theme activate:
  - planet4-another-theme
```

After that you can run this composer command to fetch and activate the theme:
```
composer update
composer run-script theme:install
```
The theme will be copied to the public folder and activated to use by the current
Wordpress installation.
