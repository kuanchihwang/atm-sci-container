#!/bin/sh
set -euo pipefail

# The command to execute, along with its arguments, is passed as `${@}` to this entry point.
# `${1}` is the command itself. If `${1}` is not supplied, default to `/bin/bash`.
if [ -z "${1:-}" ]; then
    set -- /bin/bash
fi

# If `${1}` is invalid, exit with error.
if ! command -v "${1}" 1>/dev/null 2>&1; then
    exit 1
fi

# If the container is running as root, create a non-root user, drop privileges, and execute the command afterwards.
# Use the `CONTAINER_USER`, `CONTAINER_UID`, and `CONTAINER_GID` environment variables to control how a new user is created,
# or how an existing user is reused.
if [ "$(id -u)" = "0" ]; then
    CONTAINER_USER="${CONTAINER_USER:-alice}"

    if getent passwd "${CONTAINER_USER}" 1>/dev/null 2>&1; then
        CONTAINER_UID="$(id -u "${CONTAINER_USER}")"
        CONTAINER_GID="$(id -g "${CONTAINER_USER}")"
    else
        CONTAINER_UID="${CONTAINER_UID:-1865}"
        CONTAINER_GID="${CONTAINER_GID:-${CONTAINER_UID}}"

        if ! getent group "${CONTAINER_GID}" 1>/dev/null 2>&1; then
            groupadd -g "${CONTAINER_GID}" "${CONTAINER_USER}"
        fi

        useradd -b /home -g "${CONTAINER_GID}" -m -s /bin/bash -u "${CONTAINER_UID}" "${CONTAINER_USER}"
    fi

    export HOME="$(getent passwd "${CONTAINER_USER}" | cut -d ":" -f 6)"
    export USER="${CONTAINER_USER}"

    # This branch ends right here.
    exec setpriv --reuid="${CONTAINER_UID}" --regid="${CONTAINER_GID}" --init-groups --no-new-privs "${@}"
fi

# If the container is already running as non-root, execute the command directly.
CONTAINER_USER="$(id -nu)"

export HOME="$(getent passwd "${CONTAINER_USER}" | cut -d ":" -f 6)"
export USER="${CONTAINER_USER}"

# This branch ends right here.
exec "${@}"
