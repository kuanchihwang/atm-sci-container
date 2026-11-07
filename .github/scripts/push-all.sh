#!/bin/bash
set -euo pipefail

mkdir -p logs

echo "[$(date -u "+%FT%TZ")] Begin container push"

TARGET="${1:-"push"}"
REGISTRY="${2:-"docker.io"}"
NAMESPACE="${3:-"kuanchihwang"}"
VERSION="${4:-"testing"}"

while IFS="" read -r line; do
    if [ -n "${line}" ]; then
        COMPILER="$(echo "${line}" | cut -d _ -f 1)"
        MPI="$(echo "${line}" | cut -d _ -f 2)"
        GPU="$(echo "${line}" | cut -d _ -f 3)"

        make "${TARGET}" \
            REGISTRY="${REGISTRY}" \
            NAMESPACE="${NAMESPACE}" \
            VERSION="${VERSION}" \
            COMPILER="${COMPILER}" \
            MPI="${MPI}" \
            GPU="${GPU}" \
            2>&1 | tee "logs/${TARGET}_${REGISTRY}_${NAMESPACE}_${VERSION}_${COMPILER}_${MPI}_${GPU}.log" | \
            { grep -E --line-buffered '^\[[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z\] ' || true; }
    fi
done < "$(dirname "$(realpath "${0}")")/config"

echo "[$(date -u "+%FT%TZ")] End container push"
