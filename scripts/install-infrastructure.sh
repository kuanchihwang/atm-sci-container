#!/bin/sh
set -euo pipefail

SCRIPTS_PATH="$(dirname "$(realpath "$0")")"
PATCHES_PATH="$(dirname "${SCRIPTS_PATH}")/patches"
INFRASTRUCTURE_PATH="$(dirname "${SCRIPTS_PATH}")/infrastructure"

. "${SCRIPTS_PATH}/utility-functions.sh"

###
### User options
###

if [ -z "${1:-}" ]; then
    exit 1
fi

COMPILER="$1"

INFRASTRUCTURE_LOG="${INFRASTRUCTURE_LOG:-$(basename "$0" .sh).log}"
INFRASTRUCTURE_PREFIX="${INFRASTRUCTURE_PREFIX:-/opt/hpc/infrastructure}"

HAVE_EXTERNAL_HWLOC="${HAVE_EXTERNAL_HWLOC:-false}"
HAVE_EXTERNAL_LIBCXI="${HAVE_EXTERNAL_LIBCXI:-false}"
HAVE_EXTERNAL_LIBEVENT="${HAVE_EXTERNAL_LIBEVENT:-false}"
HAVE_EXTERNAL_NUMACTL="${HAVE_EXTERNAL_NUMACTL:-false}"
HAVE_EXTERNAL_ZLIB="${HAVE_EXTERNAL_ZLIB:-false}"

###
### Individual library compilation and installation functions
###

compile_and_install_zlib() {
    case "${HAVE_EXTERNAL_ZLIB}" in
        true)
            ZLIB_PREFIX="${ZLIB_PREFIX:-/usr}"

            return
            ;;
        false)
            :
            ;;
        *)
            exit 1
            ;;
    esac

    ZLIB_PREFIX="${INFRASTRUCTURE_PREFIX}/base"

    echo ">>>>> Preparing zlib"
    extract_archive "${INFRASTRUCTURE_PATH}/zlib-1.3.1.tar.gz"
    stage_build_directory zlib-1.3.1

    echo ">>>>> Configuring zlib"
    ../source/configure --help
    # There is no way to prevent zlib from building static libraries.
    CC="${SELECTED_CC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    ../source/configure --shared --prefix="${ZLIB_PREFIX}"

    echo ">>>>> Compiling zlib"
    make_compile

    echo ">>>>> Installing zlib"
    make_install
    # Static libraries are not desired. Delete them afterwards.
    remove_static_library_from_directory "${ZLIB_PREFIX}"

    echo ">>>>> zlib - OK"
    popd
}

compile_and_install_numactl() {
    case "${HAVE_EXTERNAL_NUMACTL}" in
        true)
            NUMACTL_PREFIX="${NUMACTL_PREFIX:-/usr}"

            return
            ;;
        false)
            :
            ;;
        *)
            exit 1
            ;;
    esac

    NUMACTL_PREFIX="${INFRASTRUCTURE_PREFIX}/base"

    echo ">>>>> Preparing numactl"
    extract_archive "${INFRASTRUCTURE_PATH}/numactl-2.0.19.tar.gz"
    stage_build_directory numactl-2.0.19

    echo ">>>>> Configuring numactl"
    ../source/configure --help
    CC="${SELECTED_CC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    ../source/configure --disable-static --enable-shared --prefix="${NUMACTL_PREFIX}"
    patch_libtool_to_disable_rpath

    echo ">>>>> Compiling numactl"
    make_compile

    echo ">>>>> Installing numactl"
    make_install

    echo ">>>>> numactl - OK"
    popd
}

compile_and_install_hwloc() {
    case "${HAVE_EXTERNAL_HWLOC}" in
        true)
            HWLOC_PREFIX="${HWLOC_PREFIX:-/usr}"

            return
            ;;
        false)
            :
            ;;
        *)
            exit 1
            ;;
    esac

    HWLOC_PREFIX="${INFRASTRUCTURE_PREFIX}/base"

    echo ">>>>> Preparing hwloc"
    extract_archive "${INFRASTRUCTURE_PATH}/hwloc-2.12.2.tar.gz"
    stage_build_directory hwloc-2.12.2

    echo ">>>>> Configuring hwloc"
    ../source/configure --help
    CC="${SELECTED_CC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    CPPFLAGS="-I${NUMACTL_PREFIX}/include" \
    LDFLAGS="-L${NUMACTL_PREFIX}/lib" \
    ../source/configure --disable-static --enable-shared --prefix="${HWLOC_PREFIX}" \
        --disable-cairo \
        --disable-debug \
        --disable-doxygen \
        --enable-cpuid \
        --enable-io \
        --enable-libudev \
        --enable-libxml2 \
        --enable-pci \
        --without-x
    patch_libtool_to_disable_rpath

    echo ">>>>> Compiling hwloc"
    make_compile

    echo ">>>>> Installing hwloc"
    make_install

    echo ">>>>> hwloc - OK"
    popd
}

# The driver binaries of HPE Cray Cassini NIC are not publicly available.
# However, the source code is, at least for the user space part.
# Compile and install `libcxi` manually.
compile_and_install_libcxi() {
    case "${HAVE_EXTERNAL_LIBCXI}" in
        true)
            LIBCXI_PREFIX="${LIBCXI_PREFIX:-/usr}"

            return
            ;;
        false)
            :
            ;;
        *)
            exit 1
            ;;
    esac

    LIBCXI_PREFIX="${INFRASTRUCTURE_PREFIX}/libcxi"

    mkdir -p "${LIBCXI_PREFIX}/include"
    mkdir -p "${LIBCXI_PREFIX}/lib"
    mkdir -p "${LIBCXI_PREFIX}/share"

    extract_archive "${INFRASTRUCTURE_PATH}/shs-cassini-headers-12.0.2.tar.gz"
    cp -av shs-cassini-headers-release-shs-12.0.2/include/* "${LIBCXI_PREFIX}/include"
    cp -av shs-cassini-headers-release-shs-12.0.2/share/*   "${LIBCXI_PREFIX}/share"

    extract_archive "${INFRASTRUCTURE_PATH}/shs-cxi-driver-12.0.2.tar.gz"
    cp -av shs-cxi-driver-release-shs-12.0.2/include/*      "${LIBCXI_PREFIX}/include"

    echo ">>>>> Preparing libcxi"
    extract_archive "${INFRASTRUCTURE_PATH}/shs-libcxi-12.0.2.tar.gz"
    apply_patch_to_directory "${PATCHES_PATH}/shs-libcxi-"*".patch" shs-libcxi-release-shs-12.0.2
    pushd shs-libcxi-release-shs-12.0.2
    autoreconf -fi

    echo ">>>>> Configuring libcxi"
    ./configure --help
    CC="${SELECTED_CC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    CPPFLAGS="-I${LIBCXI_PREFIX}/include -I${NUMACTL_PREFIX}/include" \
    LDFLAGS="-L${LIBCXI_PREFIX}/lib -L${NUMACTL_PREFIX}/lib" \
    ./configure --disable-static --enable-shared --prefix="${LIBCXI_PREFIX}" \
        --without-systemdsystemunitdir \
        --without-udevrulesdir
    patch_libtool_to_disable_rpath

    echo ">>>>> Compiling libcxi"
    make_compile

    echo ">>>>> Installing libcxi"
    make_install

    echo ">>>>> libcxi - OK"
    popd
}

compile_and_install_libevent() {
    case "${HAVE_EXTERNAL_LIBEVENT}" in
        true)
            LIBEVENT_PREFIX="${LIBEVENT_PREFIX:-/usr}"

            return
            ;;
        false)
            :
            ;;
        *)
            exit 1
            ;;
    esac

    LIBEVENT_PREFIX="${INFRASTRUCTURE_PREFIX}/base"

    echo ">>>>> Preparing libevent"
    extract_archive "${INFRASTRUCTURE_PATH}/libevent-2.1.12-stable.tar.gz"
    stage_build_directory libevent-2.1.12-stable

    echo ">>>>> Configuring libevent"
    ../source/configure --help
    CC="${SELECTED_CC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    ../source/configure --disable-static --enable-shared --prefix="${LIBEVENT_PREFIX}" \
        --disable-debug-mode \
        --disable-doxygen-doc \
        --disable-libevent-regress \
        --disable-openssl \
        --disable-samples \
        --disable-verbose-debug
    patch_libtool_to_disable_rpath

    echo ">>>>> Compiling libevent"
    make_compile

    echo ">>>>> Installing libevent"
    make_install

    echo ">>>>> libevent - OK"
    popd
}

compile_and_install_pmi2() {
    echo ">>>>> Preparing PMI2"
    extract_archive "${INFRASTRUCTURE_PATH}/slurm-24.11.7.tar.bz2"
    stage_build_directory slurm-24.11.7

    echo ">>>>> Configuring PMI2"
    ../source/configure --help
    CC="${SELECTED_CC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    ../source/configure --disable-static --enable-shared --prefix="${INFRASTRUCTURE_PREFIX}/base" \
        --disable-debug \
        --disable-developer \
        --disable-memory-leak-debug \
        --enable-optimizations \
        --without-munge
    patch_libtool_to_disable_rpath

    echo ">>>>> Compiling PMI2"
    cd contribs/pmi2
    make_compile

    echo ">>>>> Installing PMI2"
    make_install

    echo ">>>>> PMI2 - OK"
    popd
}

compile_and_install_pmix() {
    echo ">>>>> Preparing PMIx"
    extract_archive "${INFRASTRUCTURE_PATH}/pmix-5.0.10.tar.gz"
    stage_build_directory pmix-5.0.10

    echo ">>>>> Configuring PMIx"
    ../source/configure --help
    CC="${SELECTED_CC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    ../source/configure --disable-static --enable-shared --prefix="${INFRASTRUCTURE_PREFIX}/base" \
        --disable-debug \
        --disable-devel-check \
        --disable-memory-sanitizers \
        --disable-sphinx \
        --disable-wrapper-rpath \
        --disable-wrapper-runpath \
        --with-hwloc="${HWLOC_PREFIX}" \
        --with-libevent="${LIBEVENT_PREFIX}" \
        --with-zlib="${ZLIB_PREFIX}" \
        --without-munge \
        --without-tests-examples
    patch_libtool_to_disable_rpath

    echo ">>>>> Compiling PMIx"
    make_compile

    echo ">>>>> Installing PMIx"
    make_install

    echo ">>>>> PMIx - OK"
    popd
}

compile_and_install_prrte() {
    echo ">>>>> Preparing PRRTE"
    extract_archive "${INFRASTRUCTURE_PATH}/prrte-3.0.13.tar.gz"
    stage_build_directory prrte-3.0.13

    echo ">>>>> Configuring PRRTE"
    ../source/configure --help
    prepend_ld_library_path "${INFRASTRUCTURE_PREFIX}/base/lib"
    CC="${SELECTED_CC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    ../source/configure --disable-static --enable-shared --prefix="${INFRASTRUCTURE_PREFIX}/base" \
        --disable-debug \
        --disable-devel-check \
        --disable-memory-sanitizers \
        --disable-sphinx \
        --with-hwloc="${HWLOC_PREFIX}" \
        --with-libevent="${LIBEVENT_PREFIX}" \
        --with-pmix="${INFRASTRUCTURE_PREFIX}/base"
    patch_libtool_to_disable_rpath

    echo ">>>>> Compiling PRRTE"
    make_compile

    echo ">>>>> Installing PRRTE"
    make_install

    restore_ld_library_path

    echo ">>>>> PRRTE - OK"
    popd
}

compile_and_install_ucx() {
    echo ">>>>> Preparing UCX"
    extract_archive "${INFRASTRUCTURE_PATH}/ucx-1.19.1.tar.gz"
    stage_build_directory ucx-1.19.1

    echo ">>>>> Configuring UCX"
    ../source/contrib/configure-release-mt --help
    # `contrib/configure-release-mt` already sets:
    # --disable-assertions
    # --disable-debug
    # --disable-logging
    # --disable-params-check
    # --enable-mt
    CC="${SELECTED_CC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    ../source/contrib/configure-release-mt --disable-static --enable-shared --prefix="${INFRASTRUCTURE_PREFIX}/ucx" \
        --disable-debug-data \
        --disable-doxygen-doc \
        --disable-examples \
        --disable-frame-pointer \
        --disable-profiling \
        --disable-stats \
        --enable-cma \
        --enable-compiler-opt \
        --enable-optimizations \
        --with-avx \
        --with-fuse3="/usr" \
        --with-knem="$(LC_ALL=C find /opt -maxdepth 1 -iname "knem-*" -print | sort | tail -n 1)" \
        --with-mad="/usr" \
        --with-rdmacm="/usr" \
        --with-verbs="/usr" \
        --with-xpmem="/usr" \
        --without-go \
        --without-java
    patch_libtool_to_disable_rpath

    echo ">>>>> Compiling UCX"
    make_compile

    echo ">>>>> Installing UCX"
    make_install

    echo ">>>>> UCX - OK"
    popd
}

compile_and_install_libfabric() {
    echo ">>>>> Preparing libfabric"
    extract_archive "${INFRASTRUCTURE_PATH}/libfabric-2.4.0.tar.bz2"
    stage_build_directory libfabric-2.4.0

    echo ">>>>> Configuring libfabric"
    ../source/configure --help
    # The CXI provider requires `--enable-static` to build successfully.
    CC="${SELECTED_CC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    CPPFLAGS="-I${INFRASTRUCTURE_PREFIX}/ucx/include -I${LIBCXI_PREFIX}/include -I${HWLOC_PREFIX}/include -I${NUMACTL_PREFIX}/include" \
    LDFLAGS="-L${INFRASTRUCTURE_PREFIX}/ucx/lib -L${LIBCXI_PREFIX}/lib -L${HWLOC_PREFIX}/lib -L${NUMACTL_PREFIX}/lib" \
    ../source/configure --enable-static --enable-shared --prefix="${INFRASTRUCTURE_PREFIX}/libfabric" \
        --disable-debug \
        --disable-monitor \
        --disable-perf \
        --disable-profile \
        --disable-trace \
        --enable-cxi="${LIBCXI_PREFIX}" \
        --enable-opx="/usr" \
        --enable-psm2="/usr" \
        --enable-psm3="/usr" \
        --enable-ucx="${INFRASTRUCTURE_PREFIX}/ucx" \
        --enable-verbs="/usr" \
        --enable-xpmem="/usr" \
        --with-numa="${NUMACTL_PREFIX}"
    patch_libtool_to_disable_rpath

    echo ">>>>> Compiling libfabric"
    make_compile

    echo ">>>>> Installing libfabric"
    make_install
    # Static libraries are not desired. Delete them afterwards.
    remove_static_library_from_directory "${INFRASTRUCTURE_PREFIX}/libfabric"

    echo ">>>>> libfabric - OK"
    popd
}

###
### Main
###

set_selected_compiler "${COMPILER}"

(
echo "This script builds and installs the infrastructure for optimized MPICH / Open MPI."
echo "It is assumed that all relevant transport drivers have already been installed."
echo ""
echo "    C Compiler: ${SELECTED_CC} ($(which "${SELECTED_CC}"))"
echo "    C Compiler Flags: ${SELECTED_CFLAGS}"
echo ""
echo "    C++ Compiler: ${SELECTED_CXX} ($(which "${SELECTED_CXX}"))"
echo "    C++ Compiler Flags: ${SELECTED_CXXFLAGS}"
echo ""
echo "    Fortran Compiler: ${SELECTED_FC} ($(which "${SELECTED_FC}"))"
echo "    Fortran Compiler Flags: ${SELECTED_FCFLAGS}"
echo ""
echo "    Install Location: ${INFRASTRUCTURE_PREFIX}"
echo ""

confirm_to_continue || exit 0
echo ""

compile_and_install_zlib
compile_and_install_numactl
compile_and_install_hwloc
compile_and_install_libcxi
compile_and_install_libevent
compile_and_install_pmi2
compile_and_install_pmix
compile_and_install_prrte
compile_and_install_ucx
compile_and_install_libfabric

patch_binary_to_set_rpath "${INFRASTRUCTURE_PREFIX}/base/bin/"* ""
patch_binary_to_set_rpath "${INFRASTRUCTURE_PREFIX}/base/lib/"* "${INFRASTRUCTURE_PREFIX}/base/lib"
patch_binary_to_set_rpath "${INFRASTRUCTURE_PREFIX}/libcxi/bin/"* ""
patch_binary_to_set_rpath "${INFRASTRUCTURE_PREFIX}/libcxi/lib/"* "${INFRASTRUCTURE_PREFIX}/libcxi/lib"
patch_binary_to_set_rpath "${INFRASTRUCTURE_PREFIX}/ucx/bin/"* ""
patch_binary_to_set_rpath "${INFRASTRUCTURE_PREFIX}/ucx/lib/"* "${INFRASTRUCTURE_PREFIX}/ucx/lib"
patch_binary_to_set_rpath "${INFRASTRUCTURE_PREFIX}/libfabric/bin/"* ""
patch_binary_to_set_rpath "${INFRASTRUCTURE_PREFIX}/libfabric/lib/"* "${INFRASTRUCTURE_PREFIX}/libfabric/lib:${INFRASTRUCTURE_PREFIX}/ucx/lib:${INFRASTRUCTURE_PREFIX}/libcxi/lib:${INFRASTRUCTURE_PREFIX}/base/lib"

remove_documentation_from_directory "${INFRASTRUCTURE_PREFIX}/"*
remove_libtool_archive_from_directory "${INFRASTRUCTURE_PREFIX}/"*
remove_pkgconfig_from_directory "${INFRASTRUCTURE_PREFIX}/"*

echo ""
echo "SUCCESSFUL COMPLETION!"
) 2>&1 | tee "${INFRASTRUCTURE_LOG}"
