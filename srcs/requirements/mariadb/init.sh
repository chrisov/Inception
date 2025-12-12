#!/bin/sh


set -e


# Configure MariaDB to listen on all network interfaces
FILE=/etc/mysql/mariadb.conf.d/50-server.cnf


# Change MariaDB to listen on all network interfaces (0.0.0.0) instead of just localhost.
sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' "$FILE"


# Create and configure runtime socket directory for MariaDB
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld || true


# Initialize data directory if not already done
if [ ! -d /var/lib/mysql/mysql ]; then
	echo "Initializing MariaDB data directory..."
	# Set up the default databases and tables
	mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi


# Start MariaDB in safe mode without networking for initial setup
mysqld_safe --skip-networking --user=mysql --socket=/run/mysqld/mysqld.sock &


# Wait for MariaDB socket to become available (up to 60 seconds)
echo "Waiting for MariaDB socket..."
for i in $(seq 1 60); do
	if mysqladmin --socket=/run/mysqld/mysqld.sock ping --silent 2>/dev/null; then
		echo "MariaDB is ready"
		break
	fi
	echo "Waiting... ($i/60)"
	sleep 1
done


# Create WordPress database and application user with necessary privileges
mysql -u root -p${MYSQL_ROOT_PASSWORD} << EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF


# Set the root password for local connections
mysql -u root -p${MYSQL_ROOT_PASSWORD} << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
EOF


# Shut down MariaDB to restart with networking enabled
mysqladmin --socket=/run/mysqld/mysqld.sock -u root -p${MYSQL_ROOT_PASSWORD} shutdown


# Start MariaDB daemon as mysql user (replaces shell process with PID 1)
exec mysqld --user=mysql