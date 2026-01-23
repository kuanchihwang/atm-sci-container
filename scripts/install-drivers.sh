#!/bin/sh
set -euo pipefail

dnf makecache
dnf install -y \
    knem libxpmem-devel \
    iefs-kernel-updates-devel ifs-kernel-updates-devel libpsm2-devel \
    rdma-core-devel
