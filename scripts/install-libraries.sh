#!/bin/sh
set -euo pipefail

SCRIPTS_PATH="$(dirname "$(realpath "$0")")"
PATCHES_PATH="$(dirname "${SCRIPTS_PATH}")/patches"
LIBRARIES_PATH="$(dirname "${SCRIPTS_PATH}")/libraries"

. "${SCRIPTS_PATH}/utility-functions.sh"

###
### User options
###

if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
    exit 1
fi

COMPILER="$1"
MPI="$2"

LIBRARIES_LOG="${LIBRARIES_LOG:-$(basename "$0" .sh).log}"
LIBRARIES_PREFIX_COMPILER_SPECIFIC="${LIBRARIES_PREFIX_COMPILER_SPECIFIC:-/opt/hpc/compiler/${COMPILER}}"
LIBRARIES_PREFIX_MPI_SPECIFIC="${LIBRARIES_PREFIX_MPI_SPECIFIC:-/opt/hpc/mpi/${COMPILER}/${MPI}}"

HAVE_EXTERNAL_LIBAEC="${HAVE_EXTERNAL_LIBAEC:-false}"
HAVE_EXTERNAL_ZLIB="${HAVE_EXTERNAL_ZLIB:-false}"
HAVE_EXTERNAL_ZSTD="${HAVE_EXTERNAL_ZSTD:-false}"

###
### Individual library compilation and installation functions
###

compile_and_install_libaec() {
    case "${HAVE_EXTERNAL_LIBAEC}" in
        true)
            LIBAEC_PREFIX="${LIBAEC_PREFIX:-/usr}"

            return
            ;;
        false)
            :
            ;;
        *)
            exit 1
            ;;
    esac

    LIBAEC_PREFIX="${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base"

    if get_milestone libaec; then
        return
    fi

    echo ">>>>> Preparing libaec"
    if [ ! -d libaec-1.1.5 ]; then
        extract_archive "${LIBRARIES_PATH}/libaec-1.1.5.tar.gz"
    fi
    stage_build_directory libaec-1.1.5

    echo ">>>>> Configuring libaec"
    ../source/configure --help
    CC="${SELECTED_CC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    ../source/configure --disable-static --enable-shared --prefix="${LIBAEC_PREFIX}"
    patch_libtool_to_disable_rpath

    echo ">>>>> Compiling libaec"
    make_compile

    echo ">>>>> Installing libaec"
    make_install

    echo ">>>>> libaec - OK"
    popd

    set_milestone libaec
}

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

    ZLIB_PREFIX="${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base"

    if get_milestone zlib; then
        return
    fi

    echo ">>>>> Preparing zlib"
    if [ ! -d zlib-1.3.1 ]; then
        extract_archive "${LIBRARIES_PATH}/zlib-1.3.1.tar.gz"
    fi
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

    set_milestone zlib
}

compile_and_install_zstd() {
    case "${HAVE_EXTERNAL_ZSTD}" in
        true)
            ZSTD_PREFIX="${ZSTD_PREFIX:-/usr}"

            return
            ;;
        false)
            :
            ;;
        *)
            exit 1
            ;;
    esac

    ZSTD_PREFIX="${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base"

    if get_milestone zstd; then
        return
    fi

    echo ">>>>> Preparing zstd"
    rm -fr zstd-1.5.7
    extract_archive "${LIBRARIES_PATH}/zstd-1.5.7.tar.gz"
    pushd zstd-1.5.7

    echo ">>>>> Configuring zstd"
    # There is no configure step for zstd.

    echo ">>>>> Compiling zstd"
    # There is no way to prevent zstd from building static libraries.
    CC="${SELECTED_CC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    make_compile prefix="${ZSTD_PREFIX}"

    echo ">>>>> Installing zstd"
    CC="${SELECTED_CC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    make_install prefix="${ZSTD_PREFIX}"
    # Static libraries are not desired. Delete them afterwards.
    remove_static_library_from_directory "${ZSTD_PREFIX}"

    echo ">>>>> zstd - OK"
    popd

    set_milestone zstd
}

compile_and_install_libjpeg() {
    if get_milestone libjpeg; then
        return
    fi

    echo ">>>>> Preparing libjpeg"
    if [ ! -d jpeg-9f ]; then
        extract_archive "${LIBRARIES_PATH}/jpegsrc.v9f.tar.gz"
    fi
    stage_build_directory jpeg-9f

    echo ">>>>> Configuring libjpeg"
    ../source/configure --help
    CC="${SELECTED_CC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    ../source/configure --disable-static --enable-shared --prefix="${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base"
    patch_libtool_to_disable_rpath

    echo ">>>>> Compiling libjpeg"
    make_compile

    echo ">>>>> Installing libjpeg"
    make_install

    echo ">>>>> libjpeg - OK"
    popd

    set_milestone libjpeg
}

compile_and_install_jasper() {
    if get_milestone jasper; then
        return
    fi

    echo ">>>>> Preparing JasPer"
    if [ ! -d jasper-2.0.33 ]; then
        extract_archive "${LIBRARIES_PATH}/jasper-2.0.33.tar.gz"
    fi
    stage_build_directory jasper-2.0.33

    echo ">>>>> Configuring JasPer"
    CC="${SELECTED_CC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    cmake \
        -D CMAKE_BUILD_TYPE="Release" \
        -D CMAKE_INSTALL_LIBDIR="lib" \
        -D CMAKE_INSTALL_PREFIX="${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base" \
        -D CMAKE_PREFIX_PATH="${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base" \
        -D CMAKE_SKIP_RPATH=TRUE \
        -D JAS_ENABLE_AUTOMATIC_DEPENDENCIES=FALSE \
        -D JAS_ENABLE_DOC=FALSE \
        -D JAS_ENABLE_LIBJPEG=TRUE \
        -D JAS_ENABLE_OPENGL=FALSE \
        -D JAS_ENABLE_PROGRAMS=TRUE \
        -D JAS_ENABLE_SHARED=TRUE \
        -B . \
        -S ../source

    echo ">>>>> Compiling JasPer"
    make_compile

    echo ">>>>> Installing JasPer"
    make_install

    echo ">>>>> JasPer - OK"
    popd

    set_milestone jasper
}

compile_and_install_libpng() {
    if get_milestone libpng; then
        return
    fi

    echo ">>>>> Preparing libpng"
    if [ ! -d libpng-1.6.54 ]; then
        extract_archive "${LIBRARIES_PATH}/libpng-1.6.54.tar.gz"
    fi
    stage_build_directory libpng-1.6.54

    echo ">>>>> Configuring libpng"
    ../source/configure --help
    CC="${SELECTED_CC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    ../source/configure --disable-static --enable-shared --prefix="${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base" \
        --disable-tests \
        --enable-hardware-optimizations \
        --enable-tools \
        --with-zlib-prefix="${ZLIB_PREFIX}"
    patch_libtool_to_disable_rpath

    echo ">>>>> Compiling libpng"
    make_compile

    echo ">>>>> Installing libpng"
    make_install

    echo ">>>>> libpng - OK"
    popd

    set_milestone libpng
}

compile_and_install_hdf5() {
    if get_milestone hdf5; then
        return
    fi

    echo ">>>>> Preparing HDF5 (Serial)"
    if [ ! -d hdf5-1.14.6 ]; then
        extract_archive "${LIBRARIES_PATH}/hdf5-1.14.6.tar.gz"
    fi
    stage_build_directory hdf5-1.14.6 hdf5-1.14.6-serial

    echo ">>>>> Configuring HDF5 (Serial)"
    ../source/configure --help
    prepend_ld_library_path "${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/lib"
    CC="${SELECTED_CC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    FC="${SELECTED_FC}" FCFLAGS="${SELECTED_FCFLAGS}" \
    ../source/configure --disable-static --enable-shared --prefix="${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/hdf5" \
        --disable-cxx \
        --disable-doxygen \
        --disable-fortran \
        --disable-java \
        --disable-parallel-tools \
        --disable-tests \
        --enable-build-mode="production" \
        --enable-hl \
        --enable-optimization="high" \
        --disable-parallel \
        --enable-tools \
        --with-szlib="${LIBAEC_PREFIX}" \
        --with-zlib="${ZLIB_PREFIX}"
    patch_libtool_to_disable_rpath

    echo ">>>>> Compiling HDF5 (Serial)"
    make_compile

    echo ">>>>> Installing HDF5 (Serial)"
    make_install

    restore_ld_library_path

    echo ">>>>> HDF5 (Serial) - OK"
    popd

    echo ">>>>> Preparing HDF5 (Parallel)"
    stage_build_directory hdf5-1.14.6 hdf5-1.14.6-parallel

    echo ">>>>> Configuring HDF5 (Parallel)"
    prepend_ld_library_path "${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/lib"
    CC="${SELECTED_MPICC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_MPICXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    FC="${SELECTED_MPIFC}" FCFLAGS="${SELECTED_FCFLAGS}" \
    ../source/configure --disable-static --enable-shared --prefix="${LIBRARIES_PREFIX_MPI_SPECIFIC}/phdf5" \
        --disable-cxx \
        --disable-doxygen \
        --disable-fortran \
        --disable-java \
        --disable-parallel-tools \
        --disable-tests \
        --enable-build-mode="production" \
        --enable-hl \
        --enable-optimization="high" \
        --enable-parallel \
        --enable-tools \
        --with-szlib="${LIBAEC_PREFIX}" \
        --with-zlib="${ZLIB_PREFIX}"
    patch_libtool_to_disable_rpath

    echo ">>>>> Compiling HDF5 (Parallel)"
    make_compile

    echo ">>>>> Installing HDF5 (Parallel)"
    make_install

    restore_ld_library_path

    echo ">>>>> HDF5 (Parallel) - OK"
    popd

    set_milestone hdf5
}

compile_and_install_pnetcdf() {
    if get_milestone pnetcdf; then
        return
    fi

    echo ">>>>> Preparing NetCDF (C, Fortran, 3, Parallel)"
    if [ ! -d pnetcdf-1.14.1 ]; then
        extract_archive "${LIBRARIES_PATH}/pnetcdf-1.14.1.tar.gz"
    fi
    stage_build_directory pnetcdf-1.14.1

    echo ">>>>> Configuring NetCDF (C, Fortran, 3, Parallel)"
    ../source/configure --help
    CC="${SELECTED_MPICC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_MPICXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    F77="${SELECTED_MPIFC}" FFLAGS="${SELECTED_FCFLAGS}" \
    FC="${SELECTED_MPIFC}" FCFLAGS="${SELECTED_FCFLAGS}" \
    ../source/configure --disable-static --enable-shared --prefix="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf3" \
        --disable-cxx \
        --disable-debug \
        --disable-doxygen \
        --enable-fortran
    patch_libtool_to_disable_rpath

    echo ">>>>> Compiling NetCDF (C, Fortran, 3, Parallel)"
    make_compile

    echo ">>>>> Installing NetCDF (C, Fortran, 3, Parallel)"
    make_install

    echo ">>>>> NetCDF (C, Fortran, 3, Parallel) - OK"
    popd

    set_milestone pnetcdf
}

compile_and_install_netcdf_c() {
    if get_milestone netcdf-c; then
        return
    fi

    echo ">>>>> Preparing NetCDF (C, 3, Serial)"
    if [ ! -d netcdf-c-4.9.3 ]; then
        extract_archive "${LIBRARIES_PATH}/netcdf-c-4.9.3.tar.gz"
    fi
    stage_build_directory netcdf-c-4.9.3 netcdf-c-4.9.3-3-serial

    echo ">>>>> Configuring NetCDF (C, 3, Serial)"
    ../source/configure --help
    prepend_ld_library_path "${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/lib"
    CC="${SELECTED_CC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    CPPFLAGS="-I${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/include" \
    LDFLAGS="-L${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/lib" \
    ../source/configure --disable-static --enable-shared --prefix="${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/netcdf3" \
        --disable-benchmarks \
        --disable-curl \
        --disable-dap \
        --disable-doxygen \
        --disable-examples \
        --disable-hdf4 \
        --disable-logging \
        --disable-nczarr \
        --disable-testsets \
        --enable-cdf5 \
        --disable-hdf5 \
        --disable-parallel4 \
        --disable-pnetcdf \
        --enable-utilities \
        --with-plugin-dir="${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/netcdf3/lib/plugin"
    patch_libtool_to_disable_rpath

    echo ">>>>> Compiling NetCDF (C, 3, Serial)"
    make_compile

    echo ">>>>> Installing NetCDF (C, 3, Serial)"
    make_install

    restore_ld_library_path

    echo ">>>>> NetCDF (C, 3, Serial) - OK"
    popd

    echo ">>>>> Preparing NetCDF (C, 4, Serial)"
    stage_build_directory netcdf-c-4.9.3 netcdf-c-4.9.3-4-serial

    echo ">>>>> Configuring NetCDF (C, 4, Serial)"
    prepend_ld_library_path "${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/hdf5/lib:${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/lib"
    CC="${SELECTED_CC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    CPPFLAGS="-I${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/hdf5/include -I${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/include" \
    LDFLAGS="-L${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/hdf5/lib -L${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/lib" \
    ../source/configure --disable-static --enable-shared --prefix="${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/netcdf4" \
        --disable-benchmarks \
        --disable-curl \
        --disable-dap \
        --disable-doxygen \
        --disable-examples \
        --disable-hdf4 \
        --disable-logging \
        --disable-nczarr \
        --disable-testsets \
        --enable-cdf5 \
        --enable-hdf5 \
        --disable-parallel4 \
        --disable-pnetcdf \
        --enable-utilities \
        --with-plugin-dir="${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/netcdf4/lib/plugin"
    patch_libtool_to_disable_rpath

    echo ">>>>> Compiling NetCDF (C, 4, Serial)"
    make_compile

    echo ">>>>> Installing NetCDF (C, 4, Serial)"
    make_install

    restore_ld_library_path

    echo ">>>>> NetCDF (C, 4, Serial) - OK"
    popd

    echo ">>>>> Preparing NetCDF (C, 4, Parallel)"
    stage_build_directory netcdf-c-4.9.3 netcdf-c-4.9.3-4-parallel

    echo ">>>>> Configuring NetCDF (C, 4, Parallel)"
    prepend_ld_library_path "${LIBRARIES_PREFIX_MPI_SPECIFIC}/phdf5/lib:${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf3/lib:${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/lib"
    CC="${SELECTED_MPICC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_MPICXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    CPPFLAGS="-I${LIBRARIES_PREFIX_MPI_SPECIFIC}/phdf5/include -I${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf3/include -I${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/include" \
    LDFLAGS="-L${LIBRARIES_PREFIX_MPI_SPECIFIC}/phdf5/lib -L${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf3/lib -L${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/lib" \
    ../source/configure --disable-static --enable-shared --prefix="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf4" \
        --disable-benchmarks \
        --disable-curl \
        --disable-dap \
        --disable-doxygen \
        --disable-examples \
        --disable-hdf4 \
        --disable-logging \
        --disable-nczarr \
        --disable-testsets \
        --enable-cdf5 \
        --enable-hdf5 \
        --enable-parallel4 \
        --enable-pnetcdf \
        --enable-utilities \
        --with-plugin-dir="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf4/lib/plugin"
    patch_libtool_to_disable_rpath

    echo ">>>>> Compiling NetCDF (C, 4, Parallel)"
    make_compile

    echo ">>>>> Installing NetCDF (C, 4, Parallel)"
    make_install

    restore_ld_library_path

    echo ">>>>> NetCDF (C, 4, Parallel) - OK"
    popd

    set_milestone netcdf-c
}

compile_and_install_netcdf_fortran() {
    if get_milestone netcdf-fortran; then
        return
    fi

    echo ">>>>> Preparing NetCDF (Fortran, 3, Serial)"
    if [ ! -d netcdf-fortran-4.6.2 ]; then
        extract_archive "${LIBRARIES_PATH}/netcdf-fortran-4.6.2.tar.gz"
    fi
    stage_build_directory netcdf-fortran-4.6.2 netcdf-fortran-4.6.2-3-serial

    echo ">>>>> Configuring NetCDF (Fortran, 3, Serial)"
    ../source/configure --help
    prepend_ld_library_path "${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/netcdf3/lib:${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/lib"
    CC="${SELECTED_CC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    F77="${SELECTED_FC}" FFLAGS="${SELECTED_FCFLAGS}" \
    FC="${SELECTED_FC}" FCFLAGS="${SELECTED_FCFLAGS}" \
    CPPFLAGS="-I${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/netcdf3/include -I${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/include" \
    LDFLAGS="-L${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/netcdf3/lib -L${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/lib" \
    HDF5_PLUGIN_PATH="${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/netcdf3/lib/plugin" \
    ../source/configure --disable-static --enable-shared --prefix="${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/netcdf3" \
        --disable-benchmarks \
        --disable-doxygen
    patch_libtool_to_disable_rpath

    echo ">>>>> Compiling NetCDF (Fortran, 3, Serial)"
    make_compile

    echo ">>>>> Installing NetCDF (Fortran, 3, Serial)"
    make_install

    restore_ld_library_path

    echo ">>>>> NetCDF (Fortran, 3, Serial) - OK"
    popd

    echo ">>>>> Preparing NetCDF (Fortran, 4, Serial)"
    stage_build_directory netcdf-fortran-4.6.2 netcdf-fortran-4.6.2-4-serial

    echo ">>>>> Configuring NetCDF (Fortran, 4, Serial)"
    prepend_ld_library_path "${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/netcdf4/lib:${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/hdf5/lib:${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/lib"
    CC="${SELECTED_CC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    F77="${SELECTED_FC}" FFLAGS="${SELECTED_FCFLAGS}" \
    FC="${SELECTED_FC}" FCFLAGS="${SELECTED_FCFLAGS}" \
    CPPFLAGS="-I${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/netcdf4/include -I${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/hdf5/include -I${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/include" \
    LDFLAGS="-L${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/netcdf4/lib -L${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/hdf5/lib -L${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/lib" \
    HDF5_PLUGIN_PATH="${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/netcdf4/lib/plugin" \
    ../source/configure --disable-static --enable-shared --prefix="${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/netcdf4" \
        --disable-benchmarks \
        --disable-doxygen
    patch_libtool_to_disable_rpath

    echo ">>>>> Compiling NetCDF (Fortran, 4, Serial)"
    make_compile

    echo ">>>>> Installing NetCDF (Fortran, 4, Serial)"
    make_install

    restore_ld_library_path

    echo ">>>>> NetCDF (Fortran, 4, Serial) - OK"
    popd

    echo ">>>>> Preparing NetCDF (Fortran, 4, Parallel)"
    stage_build_directory netcdf-fortran-4.6.2 netcdf-fortran-4.6.2-4-parallel

    echo ">>>>> Configuring NetCDF (Fortran, 4, Parallel)"
    prepend_ld_library_path "${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf4/lib:${LIBRARIES_PREFIX_MPI_SPECIFIC}/phdf5/lib:${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf3/lib:${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/lib"
    CC="${SELECTED_MPICC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_MPICXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    F77="${SELECTED_MPIFC}" FFLAGS="${SELECTED_FCFLAGS}" \
    FC="${SELECTED_MPIFC}" FCFLAGS="${SELECTED_FCFLAGS}" \
    CPPFLAGS="-I${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf4/include -I${LIBRARIES_PREFIX_MPI_SPECIFIC}/phdf5/include -I${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf3/include -I${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/include" \
    LDFLAGS="-L${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf4/lib -L${LIBRARIES_PREFIX_MPI_SPECIFIC}/phdf5/lib -L${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf3/lib -L${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/lib" \
    HDF5_PLUGIN_PATH="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf4/lib/plugin" \
    ../source/configure --disable-static --enable-shared --prefix="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf4" \
        --disable-benchmarks \
        --disable-doxygen
    patch_libtool_to_disable_rpath

    echo ">>>>> Compiling NetCDF (Fortran, 4, Parallel)"
    make_compile

    echo ">>>>> Installing NetCDF (Fortran, 4, Parallel)"
    make_install

    restore_ld_library_path

    echo ">>>>> NetCDF (Fortran, 4, Parallel) - OK"
    popd

    set_milestone netcdf-fortran
}

compile_and_install_pio() {
    if get_milestone pio; then
        return
    fi

    echo ">>>>> Preparing PIO"
    if [ ! -d ParallelIO-pio2_6_8 ]; then
        extract_archive "${LIBRARIES_PATH}/ParallelIO-2.6.8.tar.gz"
        apply_patch_to_directory "${PATCHES_PATH}/ParallelIO-"*".patch" ParallelIO-pio2_6_8
    fi
    stage_build_directory ParallelIO-pio2_6_8

    echo ">>>>> Configuring PIO"
    prepend_ld_library_path "${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf4/lib:${LIBRARIES_PREFIX_MPI_SPECIFIC}/phdf5/lib:${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf3/lib:${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/lib"
    CC="${SELECTED_MPICC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_MPICXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    FC="${SELECTED_MPIFC}" FFLAGS="${SELECTED_FCFLAGS}" \
    cmake \
        -D CMAKE_BUILD_TYPE="Release" \
        -D CMAKE_INSTALL_LIBDIR="lib" \
        -D CMAKE_INSTALL_PREFIX="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pio" \
        -D CMAKE_PREFIX_PATH="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf4:${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf3" \
        -D CMAKE_SKIP_RPATH=TRUE \
        -D GENF90_PATH="$(realpath ../source/scripts)" \
        -D NetCDF_PATH="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf4" \
        -D PnetCDF_PATH="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf3" \
        -D BUILD_SHARED_LIBS=TRUE \
        -D PIO_ENABLE_COVERAGE=FALSE \
        -D PIO_ENABLE_DOC=FALSE \
        -D PIO_ENABLE_EXAMPLES=FALSE \
        -D PIO_ENABLE_FORTRAN=TRUE \
        -D PIO_ENABLE_LOGGING=FALSE \
        -D PIO_ENABLE_TESTS=FALSE \
        -D PIO_ENABLE_TIMING=TRUE \
        -D WITH_PNETCDF=TRUE \
        -B . \
        -S ../source

    echo ">>>>> Compiling PIO"
    make_compile

    echo ">>>>> Installing PIO"
    make_install

    restore_ld_library_path

    echo ">>>>> PIO - OK"
    popd

    set_milestone pio
}

compile_and_install_lapack() {
    if get_milestone lapack; then
        return
    fi

    echo ">>>>> Preparing LAPACK"
    rm -fr lapack-3.12.1
    extract_archive "${LIBRARIES_PATH}/lapack-3.12.1.tar.gz"
    apply_patch_to_directory "${PATCHES_PATH}/lapack-"*".patch" lapack-3.12.1
    pushd lapack-3.12.1

    echo ">>>>> Configuring LAPACK"
    cp -av "${PATCHES_PATH}/lapack-make.inc" make.inc

    echo ">>>>> Compiling LAPACK"
    COMPILER="${COMPILER}" \
    SELECTED_CC="${SELECTED_CC}" SELECTED_CFLAGS="${SELECTED_CFLAGS}" \
    SELECTED_FC="${SELECTED_FC}" SELECTED_FCFLAGS="${SELECTED_FCFLAGS}" \
    make_compile blaslib cblaslib lapacklib lapackelib tmglib
    # COMPILER="${COMPILER}" \
    # SELECTED_CC="${SELECTED_CC}" SELECTED_CFLAGS="${SELECTED_CFLAGS}" \
    # SELECTED_FC="${SELECTED_FC}" SELECTED_FCFLAGS="${SELECTED_FCFLAGS}" \
    # make_compile

    echo ">>>>> Installing LAPACK"
    mkdir -p "${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/lapack/include"
    mkdir -p "${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/lapack/lib"
    cp -av CBLAS/include/*.h "${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/lapack/include"
    cp -av LAPACKE/include/*.h "${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/lapack/include"
    cp -av *.so "${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/lapack/lib"
    echo ">>>>> LAPACK - OK"
    popd

    set_milestone lapack
}

compile_and_install_esmf() {
    if get_milestone esmf; then
        return
    fi

    echo ">>>>> Preparing ESMF"
    rm -fr esmf-8.9.1
    extract_archive "${LIBRARIES_PATH}/esmf-8.9.1.tar.gz"
    extract_archive "${LIBRARIES_PATH}/yaml-cpp-0.8.0-merge-key-support.3.tar.gz"
    pushd esmf-8.9.1

    echo ">>>>> Configuring ESMF"
    # The included yaml-cpp in ESMF is at version 0.7.0, which is ancient.
    # Update it to the latest upstream version.
    cp -av ../yaml-cpp-0.8.0-merge-key-support.3/include/* src/prologue/yaml-cpp/include
    cp -av ../yaml-cpp-0.8.0-merge-key-support.3/src/* src/prologue/yaml-cpp/src
    # Massage input for ESMF.
    case "${COMPILER}" in
        gcc-*)
            SELECTED_ESMF_COMPILER="gfortran"
            ;;
        intel-*)
            SELECTED_ESMF_COMPILER="intel"
            ;;
        *)
            exit 1
            ;;
    esac
    case "${MPI}" in
        intel-mpi)
            SELECTED_ESMF_COMM="intelmpi"
            ;;
        mpich-*)
            SELECTED_ESMF_COMM="mpich"
            ;;
        open-mpi-*)
            SELECTED_ESMF_COMM="openmpi"
            ;;
        *)
            exit 1
            ;;
    esac
    SELECTED_CFLAGS_NO_PIC="$(echo ${SELECTED_CFLAGS} | sed 's/[a-z-]*pic[a-z-]*//gi' | awk '{ $1 = $1; print }')"
    SELECTED_CXXFLAGS_NO_PIC="$(echo ${SELECTED_CXXFLAGS} | sed 's/[a-z-]*pic[a-z-]*//gi' | awk '{ $1 = $1; print }')"
    SELECTED_FCFLAGS_NO_PIC="$(echo ${SELECTED_FCFLAGS} | sed 's/[a-z-]*pic[a-z-]*//gi' | awk '{ $1 = $1; print }')"

    echo ">>>>> Compiling ESMF"
    ESMF_COMPILER="${SELECTED_ESMF_COMPILER}" \
    ESMF_C="${SELECTED_MPICC}" ESMF_COPTFLAG="${SELECTED_CFLAGS_NO_PIC}" \
    ESMF_CXX="${SELECTED_MPICXX}" ESMF_CXXOPTFLAG="${SELECTED_CXXFLAGS_NO_PIC}" \
    ESMF_F90="${SELECTED_MPIFC}" ESMF_F90OPTFLAG="${SELECTED_FCFLAGS_NO_PIC}" \
    ESMF_BOPT="O" ESMF_OPTLEVEL="3" \
    ESMF_COMM="${SELECTED_ESMF_COMM}" \
    ESMF_DIR="$(pwd)" \
    ESMF_INSTALL_PREFIX="${LIBRARIES_PREFIX_MPI_SPECIFIC}/esmf" \
    ESMF_ABI="64" \
    ESMF_LAPACK="netlib" ESMF_LAPACK_LIBPATH="${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/lapack/lib" \
    ESMF_NETCDF="split" ESMF_NETCDF_INCLUDE="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf4/include" ESMF_NETCDF_LIBPATH="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf4/lib ${LIBRARIES_PREFIX_MPI_SPECIFIC}/phdf5/lib ${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf3/lib ${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/lib" \
    ESMF_PNETCDF="standard" ESMF_PNETCDF_INCLUDE="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf3/include" ESMF_PNETCDF_LIBPATH="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf3/lib" \
    ESMF_PIO="standard" ESMF_PIO_INCLUDE="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pio/include" ESMF_PIO_LIBPATH="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pio/lib" \
    make info
    # There is no way to prevent ESMF from building static libraries.
    ESMF_COMPILER="${SELECTED_ESMF_COMPILER}" \
    ESMF_C="${SELECTED_MPICC}" ESMF_COPTFLAG="${SELECTED_CFLAGS_NO_PIC}" \
    ESMF_CXX="${SELECTED_MPICXX}" ESMF_CXXOPTFLAG="${SELECTED_CXXFLAGS_NO_PIC}" \
    ESMF_F90="${SELECTED_MPIFC}" ESMF_F90OPTFLAG="${SELECTED_FCFLAGS_NO_PIC}" \
    ESMF_BOPT="O" ESMF_OPTLEVEL="3" \
    ESMF_COMM="${SELECTED_ESMF_COMM}" \
    ESMF_DIR="$(pwd)" \
    ESMF_INSTALL_PREFIX="${LIBRARIES_PREFIX_MPI_SPECIFIC}/esmf" \
    ESMF_ABI="64" \
    ESMF_LAPACK="netlib" ESMF_LAPACK_LIBPATH="${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/lapack/lib" \
    ESMF_NETCDF="split" ESMF_NETCDF_INCLUDE="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf4/include" ESMF_NETCDF_LIBPATH="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf4/lib ${LIBRARIES_PREFIX_MPI_SPECIFIC}/phdf5/lib ${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf3/lib ${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/lib" \
    ESMF_PNETCDF="standard" ESMF_PNETCDF_INCLUDE="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf3/include" ESMF_PNETCDF_LIBPATH="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf3/lib" \
    ESMF_PIO="standard" ESMF_PIO_INCLUDE="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pio/include" ESMF_PIO_LIBPATH="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pio/lib" \
    make_compile

    echo ">>>>> Installing ESMF"
    ESMF_COMPILER="${SELECTED_ESMF_COMPILER}" \
    ESMF_C="${SELECTED_MPICC}" ESMF_COPTFLAG="${SELECTED_CFLAGS_NO_PIC}" \
    ESMF_CXX="${SELECTED_MPICXX}" ESMF_CXXOPTFLAG="${SELECTED_CXXFLAGS_NO_PIC}" \
    ESMF_F90="${SELECTED_MPIFC}" ESMF_F90OPTFLAG="${SELECTED_FCFLAGS_NO_PIC}" \
    ESMF_BOPT="O" ESMF_OPTLEVEL="3" \
    ESMF_COMM="${SELECTED_ESMF_COMM}" \
    ESMF_DIR="$(pwd)" \
    ESMF_INSTALL_PREFIX="${LIBRARIES_PREFIX_MPI_SPECIFIC}/esmf" \
    ESMF_ABI="64" \
    ESMF_LAPACK="netlib" ESMF_LAPACK_LIBPATH="${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/lapack/lib" \
    ESMF_NETCDF="split" ESMF_NETCDF_INCLUDE="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf4/include" ESMF_NETCDF_LIBPATH="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf4/lib ${LIBRARIES_PREFIX_MPI_SPECIFIC}/phdf5/lib ${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf3/lib ${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/lib" \
    ESMF_PNETCDF="standard" ESMF_PNETCDF_INCLUDE="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf3/include" ESMF_PNETCDF_LIBPATH="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf3/lib" \
    ESMF_PIO="standard" ESMF_PIO_INCLUDE="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pio/include" ESMF_PIO_LIBPATH="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pio/lib" \
    make_install
    # Static libraries are not desired. Delete them afterwards.
    remove_static_library_from_directory "${LIBRARIES_PREFIX_MPI_SPECIFIC}/esmf"

    unset -v SELECTED_ESMF_COMPILER
    unset -v SELECTED_ESMF_COMM
    unset -v SELECTED_CFLAGS_NO_PIC
    unset -v SELECTED_CXXFLAGS_NO_PIC
    unset -v SELECTED_FCFLAGS_NO_PIC

    echo ">>>>> ESMF - OK"
    popd

    set_milestone esmf
}

compile_and_install_pfunit() {
    if get_milestone pfunit; then
        return
    fi

    echo ">>>>> Preparing pFUnit"
    if [ ! -d pFUnit-v4.15.0 ]; then
        extract_archive "${LIBRARIES_PATH}/pFUnit-v4.15.0.tar"
    fi
    stage_build_directory pFUnit-v4.15.0

    echo ">>>>> Configuring pFUnit"
    CC="${SELECTED_CC}" CFLAGS="${SELECTED_CFLAGS}" \
    CXX="${SELECTED_CXX}" CXXFLAGS="${SELECTED_CXXFLAGS}" \
    FC="${SELECTED_FC}" FFLAGS="${SELECTED_FCFLAGS}" \
    cmake \
        -D CMAKE_BUILD_TYPE="Release" \
        -D CMAKE_INSTALL_LIBDIR="lib" \
        -D CMAKE_INSTALL_PREFIX="${LIBRARIES_PREFIX_MPI_SPECIFIC}/pfunit" \
        -D CMAKE_PREFIX_PATH="${LIBRARIES_PREFIX_MPI_SPECIFIC}/esmf" \
        -D CMAKE_SKIP_RPATH=TRUE \
        -D BUILD_SHARED_LIBS=FALSE \
        -D ENABLE_BUILD_DOXYGEN=FALSE \
        -D ENABLE_MPI_F08=FALSE \
        -D ENABLE_TESTS=FALSE \
        -D SKIP_ESMF=TRUE \
        -D SKIP_FHAMCREST=FALSE \
        -D SKIP_MPI=FALSE \
        -D SKIP_OPENMP=FALSE \
        -D SKIP_ROBUST=FALSE \
        -B . \
        -S ../source

    echo ">>>>> Compiling pFUnit"
    make_compile

    echo ">>>>> Installing pFUnit"
    make_install

    echo ">>>>> pFUnit - OK"
    popd

    set_milestone pfunit
}

###
### Main
###

set_selected_compiler "${COMPILER}"
set_selected_mpi_compiler "${COMPILER}" "${MPI}"

(
echo "This script builds and installs optimized libraries for atmospheric models (e.g., CESM, MPAS, WRF)."
echo "It is assumed that all relevant compilers and MPI libraries have already been installed."
echo ""
echo "    C Compiler: ${SELECTED_CC} ($(which "${SELECTED_CC}"))"
echo "    MPI C Compiler: ${SELECTED_MPICC} ($(which "${SELECTED_MPICC}"))"
echo "    C Compiler Flags: ${SELECTED_CFLAGS}"
echo ""
echo "    C++ Compiler: ${SELECTED_CXX} ($(which "${SELECTED_CXX}"))"
echo "    MPI C++ Compiler: ${SELECTED_MPICXX} ($(which "${SELECTED_MPICXX}"))"
echo "    C++ Compiler Flags: ${SELECTED_CXXFLAGS}"
echo ""
echo "    Fortran Compiler: ${SELECTED_FC} ($(which "${SELECTED_FC}"))"
echo "    MPI Fortran Compiler: ${SELECTED_MPIFC} ($(which "${SELECTED_MPIFC}"))"
echo "    Fortran Compiler Flags: ${SELECTED_FCFLAGS}"
echo ""
echo "    Install Location: ${LIBRARIES_PREFIX_COMPILER_SPECIFIC} (Compiler-specific)"
echo "                      ${LIBRARIES_PREFIX_MPI_SPECIFIC} (MPI-specific)"
echo ""

confirm_to_continue || exit 0
echo ""

compile_and_install_libaec
compile_and_install_zlib
compile_and_install_zstd
compile_and_install_libjpeg
compile_and_install_jasper
compile_and_install_libpng
compile_and_install_hdf5
compile_and_install_pnetcdf
compile_and_install_netcdf_c
compile_and_install_netcdf_fortran
compile_and_install_pio
compile_and_install_lapack
compile_and_install_esmf
compile_and_install_pfunit

patch_binary_to_set_rpath "${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/bin/"* ''
patch_binary_to_set_rpath "${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/base/lib/"* ''
patch_binary_to_set_rpath "${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/hdf5/bin/"* ''
patch_binary_to_set_rpath "${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/hdf5/lib/"* ''
patch_binary_to_set_rpath "${LIBRARIES_PREFIX_MPI_SPECIFIC}/phdf5/bin/"* ''
patch_binary_to_set_rpath "${LIBRARIES_PREFIX_MPI_SPECIFIC}/phdf5/lib/"* ''
patch_binary_to_set_rpath "${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/netcdf3/bin/"* ''
patch_binary_to_set_rpath "${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/netcdf3/lib/"* ''
patch_binary_to_set_rpath "${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/netcdf4/bin/"* ''
patch_binary_to_set_rpath "${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/netcdf4/lib/"* ''
patch_binary_to_set_rpath "${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf3/bin/"* ''
patch_binary_to_set_rpath "${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf3/lib/"* ''
patch_binary_to_set_rpath "${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf4/bin/"* ''
patch_binary_to_set_rpath "${LIBRARIES_PREFIX_MPI_SPECIFIC}/pnetcdf4/lib/"* ''
patch_binary_to_set_rpath "${LIBRARIES_PREFIX_MPI_SPECIFIC}/pio/bin/"* ''
patch_binary_to_set_rpath "${LIBRARIES_PREFIX_MPI_SPECIFIC}/pio/lib/"* ''
patch_binary_to_set_rpath "${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/lapack/bin/"* ''
patch_binary_to_set_rpath "${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/lapack/lib/"* ''
patch_binary_to_set_rpath "${LIBRARIES_PREFIX_MPI_SPECIFIC}/esmf/bin/"*/*/* ''
patch_binary_to_set_rpath "${LIBRARIES_PREFIX_MPI_SPECIFIC}/esmf/lib/"*/*/* ''

remove_documentation_from_directory "${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/"*
remove_documentation_from_directory "${LIBRARIES_PREFIX_MPI_SPECIFIC}/"*
remove_libtool_archive_from_directory "${LIBRARIES_PREFIX_COMPILER_SPECIFIC}/"*
remove_libtool_archive_from_directory "${LIBRARIES_PREFIX_MPI_SPECIFIC}/"*

echo ""
echo "SUCCESSFUL COMPLETION!"
) 2>&1 | tee "${LIBRARIES_LOG}"
