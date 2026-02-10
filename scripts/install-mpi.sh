#!/bin/sh
set -euo pipefail

SCRIPTS_PATH="$(dirname "$(realpath "$0")")"
PATCHES_PATH="$(dirname "${SCRIPTS_PATH}")/patches"
MPI_PATH="$(dirname "${SCRIPTS_PATH}")/mpi"

. "${SCRIPTS_PATH}/utility-functions.sh"

###
### User options
###

if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
    exit 1
fi

COMPILER="$1"
MPI="$2"

INFRASTRUCTURE_PREFIX="${INFRASTRUCTURE_PREFIX:-/opt/hpc/infrastructure}"

MPI_LOG="${MPI_LOG:-$(basename "$0" .sh).log}"
MPI_PREFIX="${MPI_PREFIX:-/opt/hpc/compiler/${COMPILER}/${MPI}}"

HAVE_EXTERNAL_HWLOC="${HAVE_EXTERNAL_HWLOC:-false}"
HAVE_EXTERNAL_LIBEVENT="${HAVE_EXTERNAL_LIBEVENT:-false}"
HAVE_EXTERNAL_NUMACTL="${HAVE_EXTERNAL_NUMACTL:-false}"
HAVE_EXTERNAL_ZLIB="${HAVE_EXTERNAL_ZLIB:-false}"

###
### Individual library compilation and installation functions
###

compile_and_install_mpich_4() {
    case "${HAVE_EXTERNAL_HWLOC}" in
        true)
            HWLOC_PREFIX="${HWLOC_PREFIX:-/usr}"
            ;;
        false)
            HWLOC_PREFIX="${INFRASTRUCTURE_PREFIX}/base"
            ;;
        *)
            exit 1
            ;;
    esac

    echo ">>>>> Preparing MPICH"
    extract_archive "${MPI_PATH}/mpich-4.3.2.tar.gz"
    stage_build_directory mpich-4.3.2

    echo ">>>>> Configuring MPICH"
    ../source/configure --help
    CC="${SELECTED_CC}" MPICHLIB_CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" MPICHLIB_CXXFLAGS="${SELECTED_CXXFLAGS}" \
    F77="${SELECTED_FC}" MPICHLIB_FFLAGS="${SELECTED_FCFLAGS}" \
    FC="${SELECTED_FC}" MPICHLIB_FCFLAGS="${SELECTED_FCFLAGS}" \
    ../source/configure --disable-static --enable-shared --prefix="${MPI_PREFIX}" \
        --disable-cxx \
        --disable-debuginfo \
        --disable-doc \
        --disable-g \
        --disable-mutex-timing \
        --disable-timing \
        --enable-error-checking="runtime" \
        --enable-fast="avx,ndebug" \
        --enable-threads="multiple" \
        --with-device="ch4:ofi" \
        --with-hwloc="${HWLOC_PREFIX}" \
        --with-libfabric="${INFRASTRUCTURE_PREFIX}/libfabric" \
        --with-pm="hydra" \
        --with-wrapper-dl-type="none" \
        --with-xpmem="/usr"
    patch_libtool_to_disable_rpath

    echo ">>>>> Compiling MPICH"
    make_compile

    echo ">>>>> Installing MPICH"
    make_install

    echo ">>>>> MPICH - OK"
    popd
}

compile_and_install_open_mpi_4() {
    case "${HAVE_EXTERNAL_HWLOC}" in
        true)
            HWLOC_PREFIX="${HWLOC_PREFIX:-/usr}"
            ;;
        false)
            HWLOC_PREFIX="${INFRASTRUCTURE_PREFIX}/base"
            ;;
        *)
            exit 1
            ;;
    esac

    case "${HAVE_EXTERNAL_LIBEVENT}" in
        true)
            LIBEVENT_PREFIX="${LIBEVENT_PREFIX:-/usr}"
            ;;
        false)
            LIBEVENT_PREFIX="${INFRASTRUCTURE_PREFIX}/base"
            ;;
        *)
            exit 1
            ;;
    esac

    case "${HAVE_EXTERNAL_NUMACTL}" in
        true)
            NUMACTL_PREFIX="${NUMACTL_PREFIX:-/usr}"
            ;;
        false)
            NUMACTL_PREFIX="${INFRASTRUCTURE_PREFIX}/base"
            ;;
        *)
            exit 1
            ;;
    esac

    case "${HAVE_EXTERNAL_ZLIB}" in
        true)
            ZLIB_PREFIX="${ZLIB_PREFIX:-/usr}"
            ;;
        false)
            ZLIB_PREFIX="${INFRASTRUCTURE_PREFIX}/base"
            ;;
        *)
            exit 1
            ;;
    esac

    echo ">>>>> Preparing Open MPI"
    extract_archive "${MPI_PATH}/openmpi-4.1.8.tar.gz"
    apply_patch_to_directory "${PATCHES_PATH}/openmpi-4-"*".patch" openmpi-4.1.8
    stage_build_directory openmpi-4.1.8

    echo ">>>>> Configuring Open MPI"
    ../source/configure --help
    CC="${SELECTED_CC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    FC="${SELECTED_FC}" FCFLAGS="${SELECTED_FCFLAGS}" \
    CPPFLAGS="-I${NUMACTL_PREFIX}/include" \
    LDFLAGS="-L${NUMACTL_PREFIX}/lib" \
    ../source/configure --disable-static --enable-shared --prefix="${MPI_PREFIX}" \
        --disable-debug \
        --disable-io-romio \
        --disable-mem-debug \
        --disable-mem-profile \
        --disable-mpi-java \
        --disable-picky \
        --disable-timing \
        --disable-wrapper-rpath \
        --disable-wrapper-runpath \
        --enable-mpi-fortran="usempif08" \
        --with-mpi-param-check="runtime" \
        --with-cma \
        --with-hwloc="${HWLOC_PREFIX}" \
        --with-knem="$(LC_ALL=C find /opt -maxdepth 1 -iname "knem-*" -print | sort | tail -n 1)" \
        --with-libevent="${LIBEVENT_PREFIX}" \
        --with-ofi="${INFRASTRUCTURE_PREFIX}/libfabric" \
        --with-pmi="${INFRASTRUCTURE_PREFIX}/base" \
        --with-pmix="${INFRASTRUCTURE_PREFIX}/base" \
        --with-ucx="${INFRASTRUCTURE_PREFIX}/ucx" \
        --with-verbs="/usr" \
        --with-xpmem="/usr" \
        --with-zlib="${ZLIB_PREFIX}"
    patch_libtool_to_disable_rpath

    echo ">>>>> Compiling Open MPI"
    make_compile

    echo ">>>>> Installing Open MPI"
    make_install

    echo ">>>>> Open MPI - OK"
    popd
}

compile_and_install_open_mpi_5() {
    case "${HAVE_EXTERNAL_HWLOC}" in
        true)
            HWLOC_PREFIX="${HWLOC_PREFIX:-/usr}"
            ;;
        false)
            HWLOC_PREFIX="${INFRASTRUCTURE_PREFIX}/base"
            ;;
        *)
            exit 1
            ;;
    esac

    case "${HAVE_EXTERNAL_LIBEVENT}" in
        true)
            LIBEVENT_PREFIX="${LIBEVENT_PREFIX:-/usr}"
            ;;
        false)
            LIBEVENT_PREFIX="${INFRASTRUCTURE_PREFIX}/base"
            ;;
        *)
            exit 1
            ;;
    esac

    case "${HAVE_EXTERNAL_NUMACTL}" in
        true)
            NUMACTL_PREFIX="${NUMACTL_PREFIX:-/usr}"
            ;;
        false)
            NUMACTL_PREFIX="${INFRASTRUCTURE_PREFIX}/base"
            ;;
        *)
            exit 1
            ;;
    esac

    case "${HAVE_EXTERNAL_ZLIB}" in
        true)
            ZLIB_PREFIX="${ZLIB_PREFIX:-/usr}"
            ;;
        false)
            ZLIB_PREFIX="${INFRASTRUCTURE_PREFIX}/base"
            ;;
        *)
            exit 1
            ;;
    esac

    echo ">>>>> Preparing Open MPI"
    extract_archive "${MPI_PATH}/openmpi-5.0.9.tar.gz"
    stage_build_directory openmpi-5.0.9

    echo ">>>>> Configuring Open MPI"
    ../source/configure --help
    CC="${SELECTED_CC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    FC="${SELECTED_FC}" FCFLAGS="${SELECTED_FCFLAGS}" \
    CPPFLAGS="-I${NUMACTL_PREFIX}/include" \
    LDFLAGS="-L${NUMACTL_PREFIX}/lib" \
    ../source/configure --disable-static --enable-shared --prefix="${MPI_PREFIX}" \
        --disable-debug \
        --disable-devel-check \
        --disable-io-romio \
        --disable-mem-debug \
        --disable-mem-profile \
        --disable-memory-sanitizers \
        --disable-mpi-java \
        --disable-picky \
        --disable-python-bindings \
        --disable-sphinx \
        --disable-timing \
        --disable-wrapper-rpath \
        --disable-wrapper-runpath \
        --enable-mpi-fortran="usempif08" \
        --with-mpi-param-check="runtime" \
        --without-munge \
        --without-tests-examples \
        --with-cma \
        --with-hwloc="${HWLOC_PREFIX}" \
        --with-knem="$(LC_ALL=C find /opt -maxdepth 1 -iname "knem-*" -print | sort | tail -n 1)" \
        --with-libevent="${LIBEVENT_PREFIX}" \
        --with-ofi="${INFRASTRUCTURE_PREFIX}/libfabric" \
        --with-pmix="${INFRASTRUCTURE_PREFIX}/base" \
        --with-prrte="${INFRASTRUCTURE_PREFIX}/base" \
        --with-ucx="${INFRASTRUCTURE_PREFIX}/ucx" \
        --with-xpmem="/usr" \
        --with-zlib="${ZLIB_PREFIX}"
    patch_libtool_to_disable_rpath

    echo ">>>>> Compiling Open MPI"
    make_compile

    echo ">>>>> Installing Open MPI"
    make_install

    echo ">>>>> Open MPI - OK"
    popd
}

###
### Main
###

set_selected_compiler "${COMPILER}"

(
echo "This script builds and installs optimized MPICH / Open MPI."
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
echo "    Install Location: ${MPI_PREFIX}"
echo ""

confirm_to_continue || exit 0
echo ""

case "${MPI}" in
    intel-mpi)
        case "${COMPILER}" in
            intel-2024)
                sh "${MPI_PATH}/l_mpi_oneapi_p_2021.13.1.769_offline.sh" \
                    -r yes -a --action install --eula accept --silent
                rm -fr /opt/intel/oneapi/installer
                rm -fr /opt/intel/oneapi/logs
                rm -fr /opt/intel/packagemanager
                find /var/intel -mindepth 1 \
                    "!" -path "/var/intel/installercache" \
                    "!" -path "/var/intel/installercache/packagemanager.db" \
                    -delete
                ;;
            intel-2025)
                sh "${MPI_PATH}/intel-mpi-2021.17.2.94_offline.sh" \
                    -r yes -a --action install --eula accept --silent
                rm -fr /opt/intel/oneapi/installer
                rm -fr /opt/intel/oneapi/logs
                rm -fr /opt/intel/packagemanager
                find /var/intel -mindepth 1 \
                    "!" -path "/var/intel/installercache" \
                    "!" -path "/var/intel/installercache/packagemanager.db" \
                    -delete
                ;;
            *)
                exit 1
                ;;
        esac
        ;;
    mpich-4)
        compile_and_install_mpich_4

        patch_binary_to_set_rpath "${MPI_PREFIX}/bin/"* ''
        patch_binary_to_set_rpath "${MPI_PREFIX}/lib/"* '$ORIGIN'

        remove_documentation_from_directory "${MPI_PREFIX}"
        remove_libtool_archive_from_directory "${MPI_PREFIX}"
        ;;
    open-mpi-4)
        compile_and_install_open_mpi_4

        patch_binary_to_set_rpath "${MPI_PREFIX}/bin/"* ''
        patch_binary_to_set_rpath "${MPI_PREFIX}/lib/"* '$ORIGIN'

        remove_documentation_from_directory "${MPI_PREFIX}"
        remove_libtool_archive_from_directory "${MPI_PREFIX}"
        ;;
    open-mpi-5)
        compile_and_install_open_mpi_5

        patch_binary_to_set_rpath "${MPI_PREFIX}/bin/"* ''
        patch_binary_to_set_rpath "${MPI_PREFIX}/lib/"* '$ORIGIN'

        remove_documentation_from_directory "${MPI_PREFIX}"
        remove_libtool_archive_from_directory "${MPI_PREFIX}"
        ;;
    *)
        exit 1
        ;;
esac

echo ""
echo "SUCCESSFUL COMPLETION!"
) 2>&1 | tee "${MPI_LOG}"
