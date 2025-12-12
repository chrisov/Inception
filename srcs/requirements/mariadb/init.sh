#!/bin/sh

set -e

FILE=/etc/mysql/mariadb.conf.d/50-server.cnf

sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' "$FILE"

cat $FILE

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld || true

# Initialize data directory if not already done
if [ ! -d /var/lib/mysql/mysql ]; then
	echo "Initializing MariaDB data directory..."
	mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

mysqld_safe --skip-networking --user=mysql --socket=/run/mysqld/mysqld.sock &

# Wait for socket to become available (up to 60 seconds)
echo "Waiting for MariaDB socket..."
for i in $(seq 1 60); do
	if mysqladmin --socket=/run/mysqld/mysqld.sock ping --silent 2>/dev/null; then
		echo "MariaDB is ready"
		break
	fi
	echo "Waiting... ($i/60)"
	sleep 1
done

# until mysqladmin ping --silent; do
# 	echo "WE ARE PINGING"
# 	sleep 1
# done

# echo "we want to use database name -> $MYSQL_DATABASE"
# echo "user -> $MYSQL_USER with password -> $MYSQL_PASS"
# echo "did we get the password -> $MARIADB_ROOT_PASSWORD"
# echo "then grant all privilages to him"

# creating of actual db and the user through SQL syntax
# most of them are self explanatory through naming
# flushing the privileges mean that changes take effect
mysql -u root -p${MYSQL_ROOT_PASSWORD} <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

# echo "---------------------------------------"
# echo "did we go through first part of mysql?"
# echo "---------------------------------------"

mysql -u root -p${MYSQL_ROOT_PASSWORD} << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
EOF

# echo "what about mysql -u root exit value $?"

# shuts down the mariaDB to restart with all the changes
# afterwards it will run with networking enabled and in foreground
# so it will have the fake PID1 from the container
# ------------------------------------------------------
# once again simpler version is possible thankfully
# rather than -> /usr/bin/mariadb-admin we got below one
# ------------------------------------------------------
# echo "ARE WE GOING TO SHUT DOWN"

mysqladmin --socket=/run/mysqld/mysqld.sock -u root -p${MYSQL_ROOT_PASSWORD} shutdown

# DEBUG FOR FINISHING THE MARIADB SETUP
# echo "---------------------------------------"
# echo "MARIADB FINISHED SETTING UP: LETS GOOO"
# echo "---------------------------------------"

# replacing the shell with mysqld process
# making the change into PID1 as per above
# ---------------------------------------
# MariaDB explicitly rejects running as root, so --user=mysql is required
# the Debian supremacy for use is clear
# --------------------------------------
exec mysqld --user=mysql