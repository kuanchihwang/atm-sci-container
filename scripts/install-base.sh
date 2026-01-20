#!/bin/sh
set -euo pipefail

# Cache packages locally to speed up subsequent container builds.
# This must be coupled with `RUN --mount=type=cache ...` to work.
echo "keepcache=True" >> /etc/dnf/dnf.conf

# Do not install documentation to reduce container size.
echo "tsflags=nodocs" >> /etc/dnf/dnf.conf

dnf makecache
dnf update -y

dnf install -y epel-release
sed -i "/^ *\[crb\]/,/^ *\[/{/^ *enabled *= *0 *$/s//enabled=1/}" /etc/yum.repos.d/almalinux-crb.repo

dnf makecache
dnf install -y \
    binutils patchelf gcc gcc-c++ gcc-gfortran autoconf automake libtool gdb \
    diffstat diffutils git git-lfs make patch patchutils pkgconf pkgconf-pkg-config \
    bash-completion coreutils-common coreutils-single less nano perl procps-ng psmisc python-unversioned-command python3 python3-pip python3.12 python3.12-pip tcsh vim-minimal \
    ca-certificates curl-minimal hostname rsync openssh-clients wget \
    bzip2 gzip lz4 unzip xz zip zstd
dnf install -y \
    libpciaccess-devel libxml2-devel ncurses-devel systemd-devel \
    fuse-devel libconfig-devel libnl3-devel libuv-devel libyaml-devel lm_sensors-devel \
    json-c-devel libcurl-devel liburing-devel libuuid-devel \
    libevent-devel numactl-devel zlib-devel \
    fuse3-devel libcap-devel \
    bzip2-devel libzstd-devel lz4-devel xz-devel

# Install newer CMake than the distribution one.
CMAKE_VERSION="3.31.10"
mkdir -p /opt/hpc/core/cmake
wget -nv "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz"
wget -nv -O - "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-SHA-256.txt" | grep -i "cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz" | sha256sum -c -
tar -xf "cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz" -C /opt/hpc/core/cmake --no-same-owner --strip-components=1
rm -fr "cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz"
rm -fr /opt/hpc/core/cmake/doc /opt/hpc/core/cmake/man
unset -v CMAKE_VERSION
