#!/bin/bash

cd /var/www/html
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
./wp-cli.phar core download --allow-root
./wp-cli.phar config create --dbname=wordpress --dbuser=wpuser --dbpass=password --dbhost=mariadb --allow-root
./wp-cli.phar core install --url=localhost:8080 --title=inception --admin_user=dimi --admin_password=dimi --admin_email=dimi@google.com --allow-root

php-fpm8.2 -F

# use environmental variables
