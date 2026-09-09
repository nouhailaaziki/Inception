#!/bin/bash
set -euo pipefail

FTP_PASSWORD="$(cat /run/secrets/ftp_password)"

if ! id "${FTP_USER}" >/dev/null 2>&1; then
	echo "[ftp] Creating local FTP user ${FTP_USER}..."
	useradd -d /var/www/html -G www-data -s /usr/sbin/nologin "${FTP_USER}"
fi

echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd

mkdir -p /var/www/html
chmod -R g+rwX /var/www/html || true

echo "[ftp] Starting vsftpd in the foreground."
exec vsftpd /etc/vsftpd.conf
