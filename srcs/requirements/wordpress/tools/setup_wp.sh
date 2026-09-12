#!/bin/bash
set -euo pipefail

DB_PASSWORD="$(cat /run/secrets/db_password)"
WP_ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_password)"
WP_USER_PASSWORD="$(cat /run/secrets/wp_user_password)"

WP="wp --allow-root --path=/var/www/html"

MAX_RETRIES=10
RETRY=0

until mysqladmin -h mariadb -u "${MYSQL_USER}" -p"${DB_PASSWORD}" ping >/dev/null 2>&1; do
    RETRY=$((RETRY + 1))

    if [ "$RETRY" -ge "$MAX_RETRIES" ]; then
        echo "MariaDB is not available after $MAX_RETRIES attempts."
        exit 1
    fi

    echo "[wordpress] Waiting for MariaDB to accept connections... ($RETRY/$MAX_RETRIES)"
    sleep 2
done

echo "[wordpress] MariaDB is up."

if [ ! -f /var/www/html/wp-config.php ]; then
	echo "[wordpress] No installation found, installing WordPress..."

	${WP} core download

	${WP} config create \
		--dbname="${MYSQL_DATABASE}" \
		--dbuser="${MYSQL_USER}" \
		--dbpass="${DB_PASSWORD}" \
		--dbhost=mariadb

	${WP} core install \
		--url="${WP_URL}" \
		--title="${WP_TITLE}" \
		--admin_user="${WP_ADMIN_USER}" \
		--admin_password="${WP_ADMIN_PASSWORD}" \
		--admin_email="${WP_ADMIN_EMAIL}" \
		--skip-email

	${WP} user create "${WP_USER}" "${WP_USER_EMAIL}" \
		--user_pass="${WP_USER_PASSWORD}" \
		--role=editor

	# Bonus: wire up Redis object cache (best-effort, must not break the
	# mandatory part if the plugin can't be fetched, e.g. no internet).
	${WP} config set WP_REDIS_HOST redis --type=constant || true
	${WP} plugin install redis-cache --activate || true
	${WP} redis enable || true

	echo "[wordpress] Installation complete."
else
	echo "[wordpress] Existing installation found, skipping install."
fi

chown -R www-data:www-data /var/www/html

echo "[wordpress] Starting php-fpm in the foreground."
exec /usr/sbin/php-fpm8.2 -F
