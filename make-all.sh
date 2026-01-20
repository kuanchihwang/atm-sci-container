#!/bin/sh
set -euo pipefail

mkdir -p logs

echo "Container build began at $(date -u "+%FT%TZ")"

TARGET="${1:-build}"
VERSION="$(date -u "+%F")"

for COMPILER in "gcc-11" "gcc-12" "gcc-13" "gcc-14" "intel-2024" "intel-2025"; do
    for MPI in "intel-mpi" "mpich-4" "open-mpi-4" "open-mpi-5"; do
        # Filter out invalid combinations.
        case "${COMPILER}" in
            gcc-*)
                case "${MPI}" in
                    intel-mpi)
                        continue
                        ;;
                esac
                ;;
        esac

        echo "Building container with VERSION=\"${VERSION}\" COMPILER=\"${COMPILER}\" MPI=\"${MPI}\"..."
        make "${TARGET}" VERSION="${VERSION}" COMPILER="${COMPILER}" MPI="${MPI}" 1>"logs/${TARGET}_${VERSION}_${COMPILER}_${MPI}.log" 2>&1
    done
done

echo "Container build ended at $(date -u "+%FT%TZ")"
