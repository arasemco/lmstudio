#!/bin/sh
set -e

APP_USER="${APP_USER:-lms}"
APP_GROUP="${APP_GROUP:-${APP_USER}}"
PUID="${PUID:-1000}"
PGID="${PGID:-1000}"

# migrate group
if getent group "${APP_GROUP}" >/dev/null; then
    CURRENT_GID="$(getent group "${APP_GROUP}" | cut -d: -f3)"
    if [ "${CURRENT_GID}" != "${PGID}" ]; then
        groupmod -g "${PGID}" "${APP_GROUP}"
        find / -xdev -gid "${CURRENT_GID}" -exec chgrp -h "${PGID}" {} \;
    fi
else
    groupadd -g "${PGID}" "${APP_GROUP}"
fi

# migrate user
if id "${APP_USER}" >/dev/null 2>&1; then
    CURRENT_UID="$(id -u "${APP_USER}")"
    if [ "${CURRENT_UID}" != "${PUID}" ]; then
        usermod -u "${PUID}" -g "${PGID}" "${APP_USER}"
        find / -xdev -uid "${CURRENT_UID}" -exec chown -h "${PUID}" {} \;
    fi
else
    useradd -m -u "${PUID}" -g "${PGID}" -s /bin/bash "${APP_USER}"
fi

cp /etc/xdg/openbox/menu.xml /var/lib/openbox/debian-menu.xml

exec "$@"
