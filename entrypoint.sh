#!/bin/sh
set -e

APP_USER="${APP_USER:-lms}"
APP_GROUP="${APP_GROUP:-${APP_USER}}"

if ! getent group "${APP_GROUP}" >/dev/null; then
    groupadd -g "${PGID}" "${APP_GROUP}"
fi

if ! id "${APP_USER}" >/dev/null 2>&1; then
    useradd -m -u "${PUID}" -g "${PGID}" -s /bin/bash "${APP_USER}"
fi

chown -R "${APP_USER}:${APP_GROUP}" /opt/lmstudio/

exec "$@"
