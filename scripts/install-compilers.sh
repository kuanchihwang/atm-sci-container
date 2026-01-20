#!/bin/sh
set -euo pipefail

SCRIPTS_PATH="$(dirname "$(realpath "$0")")"
COMPILERS_PATH="$(dirname "${SCRIPTS_PATH}")/compilers"

###
### User options
###

if [ -z "${1:-}" ]; then
    exit 1
fi

COMPILER="$1"

###
### Main
###

case "${COMPILER}" in
    gcc-11)
        # Default in RHEL 9. Nothing to do.
        :
        ;;
    gcc-12)
        dnf install -y gcc-toolset-12
        ;;
    gcc-13)
        dnf install -y gcc-toolset-13
        ;;
    gcc-14)
        dnf install -y gcc-toolset-14
        ;;
    gcc-15)
        dnf install -y gcc-toolset-15
        ;;
    intel-2024)
        sh "${COMPILERS_PATH}/l_dpcpp-cpp-compiler_p_2024.2.1.79_offline.sh" \
            -r yes -a --action install --eula accept --silent
        sh "${COMPILERS_PATH}/l_fortran-compiler_p_2024.2.1.80_offline.sh" \
            -r yes -a --action install --eula accept --silent
        sh "${COMPILERS_PATH}/l_mpi_oneapi_p_2021.13.1.769_offline.sh" \
            -r yes -a --action install --eula accept --silent
        rm -fr /opt/intel/oneapi/installer
        rm -fr /opt/intel/oneapi/logs
        rm -fr /opt/intel/packagemanager
        rm -fr /var/intel
        ;;
    intel-2025)
        sh "${COMPILERS_PATH}/intel-dpcpp-cpp-compiler-2025.3.1.16_offline.sh" \
            -r yes -a --action install --eula accept --silent
        sh "${COMPILERS_PATH}/intel-fortran-compiler-2025.3.1.16_offline.sh" \
            -r yes -a --action install --eula accept --silent
        sh "${COMPILERS_PATH}/intel-mpi-2021.17.1.13_offline.sh" \
            -r yes -a --action install --eula accept --silent
        rm -fr /opt/intel/oneapi/installer
        rm -fr /opt/intel/oneapi/logs
        rm -fr /opt/intel/packagemanager
        rm -fr /var/intel
        ;;
    *)
        exit 1
        ;;
esac
