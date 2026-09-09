#!/bin/bash
set -euo pipefail

CERT_DIR=/etc/nginx/ssl
mkdir -p "${CERT_DIR}"

if [ ! -f "${CERT_DIR}/inception.crt" ]; then
	echo "[nginx] Generating self-signed TLS certificate for ${DOMAIN_NAME}..."
	openssl req -x509 -nodes -days 365 \
		-newkey rsa:2048 \
		-keyout "${CERT_DIR}/inception.key" \
		-out "${CERT_DIR}/inception.crt" \
		-subj "/C=MA/ST=BeniMellal-Khenifra/L=Khouribga/O=42Network/OU=Inception/CN=${DOMAIN_NAME}"
fi

envsubst '${DOMAIN_NAME}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

echo "[nginx] Starting nginx in the foreground."
exec nginx -g "daemon off;"
