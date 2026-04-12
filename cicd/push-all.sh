#!/bin/sh
set -euo pipefail

mkdir -p logs

echo "[$(date -u "+%FT%TZ")] Begin container push"

TARGET="${1:-"push"}"
REGISTRY="${2:-"docker.io"}"
NAMESPACE="${3:-"kuanchihwang"}"
VERSION="${4:-"testing"}"

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

        echo "[$(date -u "+%FT%TZ")] Pushing container with"
        echo "    REGISTRY=\"${REGISTRY}\""
        echo "    NAMESPACE=\"${NAMESPACE}\""
        echo "    VERSION=\"${VERSION}\""
        echo "    COMPILER=\"${COMPILER}\""
        echo "    MPI=\"${MPI}\""
        make "${TARGET}" \
            REGISTRY="${REGISTRY}" \
            NAMESPACE="${NAMESPACE}" \
            VERSION="${VERSION}" \
            COMPILER="${COMPILER}" \
            MPI="${MPI}" \
            1>"logs/${TARGET}_${REGISTRY}_${NAMESPACE}_${VERSION}_${COMPILER}_${MPI}.log" 2>&1
    done
done

echo "[$(date -u "+%FT%TZ")] End container push"
