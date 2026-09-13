#!/bin/bash
set -euo pipefail

DB_ROOT_PASSWORD="$(cat /run/secrets/db_root_password)"
DB_PASSWORD="$(cat /run/secrets/db_password)"

# Volume may be mounted with root ownership on first run.
mkdir -p /var/lib/mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql /run/mysqld

if [ ! -d "/var/lib/mysql/mysql" ]; then
	echo "[mariadb] No existing database found, initializing..."

	mariadb-install-db --user=mysql --datadir=/var/lib/mysql \
		--auth-root-authentication-method=normal >/dev/null

	# Start a temporary, socket-only instance to run bootstrap SQL.
		mariadbd --user=mysql --datadir=/var/lib/mysql --bootstrap <<-EOSQL
			ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
			CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
			CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
			GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
			CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
			GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
			FLUSH PRIVILEGES;
		EOSQL
	echo "[mariadb] Bootstrap complete."
else
	echo "[mariadb] Existing database found, skipping initialization."
fi

echo "[mariadb] Starting MariaDB in the foreground."
exec mariadbd --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0
