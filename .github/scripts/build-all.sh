#!/bin/bash
set -euo pipefail

mkdir -p logs

echo "[$(date -u "+%FT%TZ")] Begin container build"

TARGET="${1:-"build"}"
VERSION="${2:-"testing"}"

while IFS="" read -r line; do
    if [ -n "${line}" ]; then
        COMPILER="$(echo "${line}" | cut -d _ -f 1)"
        MPI="$(echo "${line}" | cut -d _ -f 2)"
        GPU="$(echo "${line}" | cut -d _ -f 3)"

        make "${TARGET}" \
            VERSION="${VERSION}" \
            COMPILER="${COMPILER}" \
            MPI="${MPI}" \
            GPU="${GPU}" \
            2>&1 | tee "logs/${TARGET}_${VERSION}_${COMPILER}_${MPI}_${GPU}.log" | \
            { grep -E --line-buffered '^\[[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z\] ' || true; }
    fi
done < "$(dirname "$(realpath "${0}")")/config"

echo "[$(date -u "+%FT%TZ")] End container build"
