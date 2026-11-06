#!/bin/sh
set -euo pipefail

SCRIPTS_PATH="$(dirname "$(realpath "${0}")")"
COMPILERS_PATH="$(dirname "${SCRIPTS_PATH}")/bin/compilers"

###
### User options
###

if [ -z "${1:-}" ]; then
    exit 1
fi

COMPILER="${1}"

###
### Main
###

case "${COMPILER}" in
    gnu-11)
        # Default in RHEL 9. Nothing to do.
        :
        ;;
    gnu-12)
        dnf -y install gcc-toolset-12
        rm -fr /etc/profile.d/modules.* /etc/profile.d/scl-init.*
        ;;
    gnu-13)
        dnf -y install gcc-toolset-13
        rm -fr /etc/profile.d/modules.* /etc/profile.d/scl-init.*
        ;;
    gnu-14)
        dnf -y install gcc-toolset-14
        rm -fr /etc/profile.d/modules.* /etc/profile.d/scl-init.*
        ;;
    gnu-15)
        dnf -y install gcc-toolset-15
        rm -fr /etc/profile.d/modules.* /etc/profile.d/scl-init.*
        ;;
    intel-2024)
        sh "${COMPILERS_PATH}/l_dpcpp-cpp-compiler_p_2024.2.1.79_offline.sh" \
            -r yes -a --action install --eula accept --silent
        sh "${COMPILERS_PATH}/l_fortran-compiler_p_2024.2.1.80_offline.sh" \
            -r yes -a --action install --eula accept --silent
        rm -fr /opt/intel/oneapi/installer
        rm -fr /opt/intel/oneapi/logs
        rm -fr /opt/intel/packagemanager
        find /var/intel -mindepth 1 \
            "!" -path "/var/intel/installercache" \
            "!" -path "/var/intel/installercache/packagemanager.db" \
            -delete
        # Shush Intel `ifort` compiler about its deprecation message.
        echo "-diag-disable=10448" > /opt/intel/oneapi/compiler/latest/bin/ifort.cfg
        ;;
    intel-2025)
        sh "${COMPILERS_PATH}/intel-dpcpp-cpp-compiler-2025.3.3.17_offline.sh" \
            -r yes -a --action install --eula accept --silent
        sh "${COMPILERS_PATH}/intel-fortran-compiler-2025.3.3.15_offline.sh" \
            -r yes -a --action install --eula accept --silent
        rm -fr /opt/intel/oneapi/installer
        rm -fr /opt/intel/oneapi/logs
        rm -fr /opt/intel/packagemanager
        find /var/intel -mindepth 1 \
            "!" -path "/var/intel/installercache" \
            "!" -path "/var/intel/installercache/packagemanager.db" \
            -delete
        ;;
    nvidia-2026)
        NVHPC_INSTALL_DIR="/opt/nvidia/hpc-sdk" \
        NVHPC_INSTALL_TYPE="single" \
        NVHPC_SILENT="true" \
        "${COMPILERS_PATH}/nvidia-hpc-sdk/x86_64/install"
        rm -fr /opt/nvidia/hpc-sdk/modulefiles
        for d in REDIST cmake comm_libs examples math_libs profilers; do
            rm -fr "/opt/nvidia/hpc-sdk/$(uname -s)_$(uname -m)/2026/${d}"
        done
        unset d
        # Use custom CUDA instead of the bundled one.
        rm -fr "/opt/nvidia/hpc-sdk/$(uname -s)_$(uname -m)/2026/cuda/"*
        for d in bin include lib64 nvvm; do
            ln -s "${GPU_PREFIX}/${d}" "/opt/nvidia/hpc-sdk/$(uname -s)_$(uname -m)/2026/cuda/${d}"
        done
        unset d
        ;;
    *)
        exit 1
        ;;
esac
