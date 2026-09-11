#!/bin/sh
set -eu

DOCKER_GID="$(stat -c '%g' /var/run/docker.sock)"

if ! getent group "$DOCKER_GID" >/dev/null 2>&1; then
    groupadd -g "$DOCKER_GID" dockersock
fi

DOCKER_GROUP="$(getent group "$DOCKER_GID" | cut -d: -f1)"

usermod -aG "$DOCKER_GROUP" netdata

exec netdata -D
