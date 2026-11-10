#!/bin/sh
set -euo pipefail

if [ -z "${1:-}" ]; then
    exit 1
fi

GPU="${1}"

case "${GPU}" in
    cuda-12)
        dnf -y config-manager --add-repo "https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo"
        dnf makecache
        # Only allow DNF to pick packages from the `cuda-*` repository.
        dnf -y --disablerepo="*" --enablerepo="cuda-rhel9-x86_64" install \
            cuda-command-line-tools-12-9 cuda-minimal-build-12-9 \
            cuda-cudart-devel-12-9 cuda-driver-devel-12-9 cuda-nvml-devel-12-9 libcublas-devel-12-9
        dnf -y config-manager --set-disabled cuda-rhel9-x86_64
        rm -fr /etc/ld.so.conf.d/*cuda*.conf
        while IFS="" read -r f; do
            # Remove the static library if the shared one also exists, but spare the CUDA runtime library.
            if [ -f "${f%_static.a}.so" ] && [ "$(basename "${f}")" != "libcudart_static.a" ]; then
                du -h "${f}"
                rm -f "${f}"
            fi
        done <<< "$(find /usr/local/cuda-12.9 -iname "lib*_static.a" -print)"
        unset f
        ;;
    cuda-13)
        dnf -y config-manager --add-repo "https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo"
        dnf makecache
        # Only allow DNF to pick packages from the `cuda-*` repository.
        dnf -y --disablerepo="*" --enablerepo="cuda-rhel9-x86_64" install \
            cuda-command-line-tools-13-0 cuda-minimal-build-13-0 \
            cuda-cudart-devel-13-0 cuda-driver-devel-13-0 cuda-nvml-devel-13-0 libcublas-devel-13-0
        dnf -y config-manager --set-disabled cuda-rhel9-x86_64
        rm -fr /etc/ld.so.conf.d/*cuda*.conf
        while IFS="" read -r f; do
            # Remove the static library if the shared one also exists, but spare the CUDA runtime library.
            if [ -f "${f%_static.a}.so" ] && [ "$(basename "${f}")" != "libcudart_static.a" ]; then
                du -h "${f}"
                rm -f "${f}"
            fi
        done <<< "$(find /usr/local/cuda-13.0 -iname "lib*_static.a" -print)"
        unset f
        ;;
    none)
        :
        ;;
    *)
        exit 1
        ;;
esac

dnf makecache
# Only allow DNF to pick packages from the `doca` repository.
dnf -y --disablerepo="*" --enablerepo="doca" install \
    knem libxpmem libxpmem-devel rdma-core rdma-core-devel \
    infiniband-diags libibverbs-utils librdmacm-utils
# Only allow DNF to pick packages from the `cornelis-opxs` repository.
LIBPSM2_DEVEL="$(dnf -q --disablerepo="*" --enablerepo="cornelis-opxs" repoquery \
    libpsm2-devel | \
    grep -E -v "cuda|rocm" | \
    head -n 1)"
dnf -y --disablerepo="*" --enablerepo="cornelis-opxs" install \
    "${LIBPSM2_DEVEL}"
unset LIBPSM2_DEVEL
# Only allow DNF to pick packages from the `intel-efs` repository.
dnf -y --disablerepo="*" --enablerepo="intel-efs" install \
    iefs-kernel-updates-devel

# Install only the header files necessary for building the OPX provider in `libfabric`.
# This can be achieved by installing `ifs-kernel-updates-devel` before, but recent versions (12+) of
# Cornelis OPX Software no longer package it independently. Resort to magic file surgery here.
OPXS_KERNEL_UPDATES="$(find /mnt/bin/drivers/cornelis-opxs -maxdepth 1 \
    -name "opxs-kernel-updates-*.src.rpm" -print | \
    grep -E -v "cuda|rocm" | \
    head -n 1)"
mkdir -p opxs-kernel-updates
rpm2archive -n < "${OPXS_KERNEL_UPDATES}" | \
    tar -xf - -C opxs-kernel-updates --no-same-owner
tar -xf opxs-kernel-updates/opxs-kernel-updates-*.tgz -C opxs-kernel-updates --no-same-owner --strip-components=1
cp -av opxs-kernel-updates/include/uapi /usr/include
rm -fr opxs-kernel-updates
unset OPXS_KERNEL_UPDATES
