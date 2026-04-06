#!/bin/sh
set -euo pipefail

mkdir -p logs

echo "Container build began at $(date -u "+%FT%TZ")"

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

        echo "Building container with"
        echo "    VERSION=\"${VERSION}\""
        echo "    COMPILER=\"${COMPILER}\""
        echo "    MPI=\"${MPI}\""
        make "${TARGET}" \
            VERSION="${VERSION}" \
            COMPILER="${COMPILER}" \
            MPI="${MPI}" \
            1>"logs/${TARGET}_${VERSION}_${COMPILER}_${MPI}.log" 2>&1
    done
done

echo "Container build ended at $(date -u "+%FT%TZ")"
