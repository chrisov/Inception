#!/bin/bash


set -e


# Set working directory for WordPress installation
cd /var/www/html


# Download WP-CLI command-line tool if not already present
if [ ! -f wp-cli.phar ]; then
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
fi


# Download and install WordPress core (one-time setup)
if [ ! -f wp-config.php ]; then
    # Download WordPress files
    ./wp-cli.phar core download --allow-root
    
    # Wait for MariaDB to be ready before proceeding with setup
    echo "Waiting for database..."
    for i in $(seq 1 60); do
        if mysqladmin -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" ping 2>/dev/null; then
            echo "Database is ready"
            break
        fi
        echo "Waiting for database... ($i/60)"
        sleep 1
    done
    
    # Generate WordPress configuration file with database credentials
    ./wp-cli.phar config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost=mariadb \
        --allow-root
    
    # Initialize WordPress database and create admin user
    ./wp-cli.phar core install \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${DB_EMAIL}" \
        --allow-root

    # Enable comment moderation so user comments require admin approval
    ./wp-cli.phar option update comment_moderation 1 --allow-root
fi


# Create or verify non-admin subscriber user (runs on every startup for idempotence)
if [ -n "${WP_USER}" ] && [ -n "${WP_USER_PASSWORD}" ] && [ -n "${WP_USER_EMAIL}" ]; then
    # Try to create user; if it exists, skip gracefully
    if ! ./wp-cli.phar user get "${WP_USER}" --field=ID --allow-root >/dev/null 2>&1; then
        ./wp-cli.phar user create "${WP_USER}" "${WP_USER_EMAIL}" \
            --role="${WP_USER_ROLE:-subscriber}" \
            --user_pass="${WP_USER_PASSWORD}" \
            --allow-root >/dev/null
        echo "Successfully created user: ${WP_USER}"
    else
        echo "User ${WP_USER} already exists."
    fi
else
    echo "WP_USER, WP_USER_PASSWORD, or WP_USER_EMAIL not set; skipping user check."
fi


# Start PHP-FPM service (replaces shell process with PID 1)
exec php-fpm8.2 -F
