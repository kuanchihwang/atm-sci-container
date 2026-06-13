#!/bin/sh
set -euo pipefail

# Cache packages locally to speed up subsequent container builds.
# This must be coupled with `RUN --mount=type=cache ...` to work.
echo "keepcache=True" >> /etc/dnf/dnf.conf

# Do not install documentation to reduce container size.
echo "tsflags=nodocs" >> /etc/dnf/dnf.conf

dnf makecache
dnf -y update

dnf -y install epel-release
sed -i "/^ *\[crb\]/,/^ *\[/{/^ *enabled *= *0 *$/s//enabled=1/}" /etc/yum.repos.d/almalinux-crb.repo

dnf makecache
dnf -y install \
    binutils gcc gcc-c++ gcc-gfortran autoconf automake libtool gdb \
    diffstat diffutils git git-lfs make patch patchutils pkgconf pkgconf-pkg-config \
    bash-completion coreutils-common coreutils-single jq less perl-interpreter procps-ng psmisc python-unversioned-command python3 python3-pip python3-setuptools python3.12 python3.12-pip python3.12-setuptools tcsh time vim-minimal yq \
    ca-certificates curl-minimal hostname openssh-clients rsync wget \
    bzip2 gzip lz4 unzip xz zip zstd
dnf -y install \
    bzip2-devel libzstd-devel lz4-devel xz-devel \
    libnl3-devel pciutils \
    numactl-devel \
    libpciaccess-devel libxml2-devel ncurses-devel systemd-devel \
    fuse-devel libconfig-devel libuv-devel libyaml-devel lm_sensors-devel \
    json-c-devel libcurl-devel liburing-devel libuuid-devel \
    libevent-devel zlib-devel \
    fuse3-devel libcap-devel \
    libtirpc-devel
# In RHEL 9+, do not modify the system Python, and do not use `alternatives` to manage the unversioned Python.
# https://developers.redhat.com/articles/2025/09/30/how-change-meaning-python-and-python3-rhel
ln -s /usr/bin/python3.12 /usr/local/bin/python
ln -s /usr/bin/python3.12 /usr/local/bin/python3
# In `libtirpc-devel`, `/usr/include/tirpc/rpc/types.h` has `#include <netconfig.h>`, but `netconfig.h`
# is not in the default include path, `/usr/include`. This causes WRF to fail to build.
ln -s tirpc/netconfig.h /usr/include/netconfig.h

# Install newer CMake than the distribution one.
CMAKE_VERSION="3.31.12"
mkdir -p /opt/hpc/core/cmake
wget -nv "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz"
wget -nv -O - "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-SHA-256.txt" | grep -i "cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz" | sha256sum -c -
tar -xf "cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz" -C /opt/hpc/core/cmake --no-same-owner --strip-components=1
rm -fr "cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz"
rm -fr /opt/hpc/core/cmake/doc /opt/hpc/core/cmake/man
unset -v CMAKE_VERSION
