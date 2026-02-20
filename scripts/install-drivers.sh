#!/bin/sh
set -euo pipefail

dnf makecache
dnf -y --disablerepo="*" --enablerepo="doca" install \
    knem libxpmem-devel rdma-core-devel
LIBPSM2_DEVEL="$(dnf -q --disablerepo="*" --enablerepo="cornelis-opxs" repoquery \
    libpsm2-devel | \
    grep -E -v "cuda|rocm" | \
    head -n 1)"
dnf -y --disablerepo="*" --enablerepo="cornelis-opxs" install \
    "${LIBPSM2_DEVEL}"
unset -v LIBPSM2_DEVEL
dnf -y --disablerepo="*" --enablerepo="intel-efs" install \
    iefs-kernel-updates-devel

# Install only the header files necessary for building the OPX provider in `libfabric`.
# This can be achieved by installing `ifs-kernel-updates-devel` before, but recent versions (12-) of
# Cornelis OPX Software no longer package it independently. Resort to some copying magic here.
OPXS_KERNEL_UPDATES="$(find /mnt/drivers/cornelis-opxs -maxdepth 1 \
    -name "opxs-kernel-updates-*.src.rpm" -print | \
    grep -E -v "cuda|rocm" | \
    head -n 1)"
mkdir -p opxs-kernel-updates
cat "${OPXS_KERNEL_UPDATES}" | \
    rpm2archive -n - | \
    tar -xf - -C opxs-kernel-updates --no-same-owner
tar -xf opxs-kernel-updates/opxs-kernel-updates-*.tgz -C opxs-kernel-updates --no-same-owner --strip-components=1
cp -av opxs-kernel-updates/include/uapi /usr/include
rm -fr opxs-kernel-updates
unset -v OPXS_KERNEL_UPDATES
