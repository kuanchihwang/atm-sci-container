#!/bin/bash
set -euo pipefail

mkdir -p logs

echo "[$(date -u "+%FT%TZ")] Begin container build"

TARGET="${1:-"build"}"
VERSION="${2:-"testing"}"

for MPI in "mpich-4" "open-mpi-4" "open-mpi-5" "intel-mpi"; do
    for COMPILER in "gnu-11" "gnu-12" "gnu-13" "gnu-14" "gnu-15" "intel-2024" "intel-2025"; do
        # Filter out invalid combinations.
        case "${MPI}" in
            intel-mpi)
                case "${COMPILER}" in
                    gnu-*)
                        continue
                        ;;
                esac
                ;;
        esac

        make "${TARGET}" \
            VERSION="${VERSION}" \
            COMPILER="${COMPILER}" \
            MPI="${MPI}" \
            2>&1 | tee "logs/${TARGET}_${VERSION}_${COMPILER}_${MPI}.log" | \
            { grep -E --line-buffered '^\[[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z\] ' || true; }
    done
done

echo "[$(date -u "+%FT%TZ")] End container build"
