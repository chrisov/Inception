#!/bin/bash

set -e

cd /var/www/html

# Download WP-CLI if not exists
if [ ! -f wp-cli.phar ]; then
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
fi

# Download WordPress core if not exists
if [ ! -f wp-config.php ]; then
    ./wp-cli.phar core download --allow-root
    
    # Wait for database to be ready using mysqladmin ping
    echo "Waiting for database..."
    for i in $(seq 1 60); do
        if mysqladmin -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" ping 2>/dev/null; then
            echo "Database is ready"
            break
        fi
        echo "Waiting for database... ($i/60)"
        sleep 1
    done
    
    # Create wp-config.php
    ./wp-cli.phar config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost=mariadb \
        --allow-root
    
    # Install WordPress
    ./wp-cli.phar core install \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${DB_EMAIL}" \
        --allow-root

    # Enable comment moderation by default
    ./wp-cli.phar option update comment_moderation 1 --allow-root

    # Optionally create a non-admin user if env vars are provided
    if [ -n "${WP_USER}" ] && [ -n "${WP_USER_PASSWORD}" ] && [ -n "${WP_USER_EMAIL}" ]; then
        echo "Creating additional WordPress user: ${WP_USER}"
        # Try to create user; if it exists, skip gracefully
        if ! ./wp-cli.phar user get "${WP_USER}" --field=ID --allow-root >/dev/null 2>&1; then
            ./wp-cli.phar user create "${WP_USER}" "${WP_USER_EMAIL}" \
                --role="${WP_USER_ROLE:-subscriber}" \
                --user_pass="${WP_USER_PASSWORD}" \
                --allow-root
        else
            echo "User ${WP_USER} already exists; skipping creation."
        fi
    else
        echo "WP_USER, WP_USER_PASSWORD, or WP_USER_EMAIL not set; skipping additional user creation."
    fi
fi

# Start PHP-FPM
exec php-fpm8.2 -F
