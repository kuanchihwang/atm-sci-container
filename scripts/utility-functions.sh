#!/bin/sh

set_selected_compiler() {
    if [ "${#}" -ne 1 ]; then
        return 1
    fi

    case "${1}" in
        gcc-11|gcc-12|gcc-13|gcc-14)
            SELECTED_CC="${SELECTED_CC:-gcc}"
            SELECTED_CFLAGS="${SELECTED_CFLAGS:--fPIC -march=x86-64-v3 -mtune=znver3 -O3}"
            SELECTED_CXX="${SELECTED_CXX:-g++}"
            SELECTED_CXXFLAGS="${SELECTED_CXXFLAGS:--fPIC -march=x86-64-v3 -mtune=znver3 -O3}"
            SELECTED_FC="${SELECTED_FC:-gfortran}"
            SELECTED_FCFLAGS="${SELECTED_FCFLAGS:--fPIC -march=x86-64-v3 -mtune=znver3 -O3}"
            ;;
        gcc-15)
            SELECTED_CC="${SELECTED_CC:-gcc}"
            SELECTED_CFLAGS="${SELECTED_CFLAGS:--fPIC -march=x86-64-v3 -mtune=znver3 -O3 -std=gnu17}"
            SELECTED_CXX="${SELECTED_CXX:-g++}"
            SELECTED_CXXFLAGS="${SELECTED_CXXFLAGS:--fPIC -march=x86-64-v3 -mtune=znver3 -O3 -std=gnu++17}"
            SELECTED_FC="${SELECTED_FC:-gfortran}"
            SELECTED_FCFLAGS="${SELECTED_FCFLAGS:--fPIC -march=x86-64-v3 -mtune=znver3 -O3}"
            ;;
        intel-2024)
            SELECTED_CC="${SELECTED_CC:-icx}"
            SELECTED_CFLAGS="${SELECTED_CFLAGS:--fpic -march=core-avx2 -mtune=core-avx2 -O3}"
            SELECTED_CXX="${SELECTED_CXX:-icpx}"
            SELECTED_CXXFLAGS="${SELECTED_CXXFLAGS:--fpic -march=core-avx2 -mtune=core-avx2 -O3}"
            SELECTED_FC="${SELECTED_FC:-ifort}"
            SELECTED_FCFLAGS="${SELECTED_FCFLAGS:--fpic -march=core-avx2 -mtune=core-avx2 -O3}"
            ;;
        intel-2025)
            SELECTED_CC="${SELECTED_CC:-icx}"
            SELECTED_CFLAGS="${SELECTED_CFLAGS:--fpic -march=core-avx2 -mtune=core-avx2 -O3}"
            SELECTED_CXX="${SELECTED_CXX:-icpx}"
            SELECTED_CXXFLAGS="${SELECTED_CXXFLAGS:--fpic -march=core-avx2 -mtune=core-avx2 -O3}"
            SELECTED_FC="${SELECTED_FC:-ifx}"
            SELECTED_FCFLAGS="${SELECTED_FCFLAGS:--fpic -march=core-avx2 -mtune=core-avx2 -O3}"
            ;;
        *)
            return 1
            ;;
    esac

    if ! which "${SELECTED_CC}" "${SELECTED_CXX}" "${SELECTED_FC}" 1>/dev/null 2>&1; then
        unset -v SELECTED_CC SELECTED_CFLAGS
        unset -v SELECTED_CXX SELECTED_CXXFLAGS
        unset -v SELECTED_FC SELECTED_FCFLAGS

        return 1
    fi

    return 0
}

set_selected_mpi_compiler() {
    if [ "${#}" -ne 2 ]; then
        return 1
    fi

    case "${2}" in
        intel-mpi)
            case "${1}" in
                intel-2024)
                    SELECTED_MPICC="${SELECTED_MPICC:-mpiicx}"
                    SELECTED_MPICXX="${SELECTED_MPICXX:-mpiicpx}"
                    SELECTED_MPIFC="${SELECTED_MPIFC:-mpiifort}"
                    ;;
                intel-2025)
                    SELECTED_MPICC="${SELECTED_MPICC:-mpiicx}"
                    SELECTED_MPICXX="${SELECTED_MPICXX:-mpiicpx}"
                    SELECTED_MPIFC="${SELECTED_MPIFC:-mpiifx}"
                    ;;
                *)
                    return 1
                    ;;
            esac
            ;;
        mpich-4)
            SELECTED_MPICC="${SELECTED_MPICC:-mpicc}"
            SELECTED_MPICXX="${SELECTED_MPICXX:-mpic++}"
            SELECTED_MPIFC="${SELECTED_MPIFC:-mpifort}"
            ;;
        open-mpi-4|open-mpi-5)
            SELECTED_MPICC="${SELECTED_MPICC:-mpicc}"
            SELECTED_MPICXX="${SELECTED_MPICXX:-mpic++}"
            SELECTED_MPIFC="${SELECTED_MPIFC:-mpifort}"
            ;;
        *)
            return 1
            ;;
    esac

    if ! which "${SELECTED_MPICC}" "${SELECTED_MPICXX}" "${SELECTED_MPIFC}" 1>/dev/null 2>&1; then
        unset -v SELECTED_MPICC
        unset -v SELECTED_MPICXX
        unset -v SELECTED_MPIFC

        return 1
    fi

    return 0
}

confirm_to_continue() {
    while true; do
        echo "Continue? (Yy/Nn):"
        read -r USER_RESPONSE

        if [ "${USER_RESPONSE}" = "Y" ] || [ "${USER_RESPONSE}" = "y" ]; then
            unset -v USER_RESPONSE

            return 0
        elif [ "${USER_RESPONSE}" = "N" ] || [ "${USER_RESPONSE}" = "n" ]; then
            unset -v USER_RESPONSE

            return 1
        else
            echo "Invalid response!"
        fi
    done
}

package_is_installed() {
    if [ "${#}" -ne 1 ]; then
        return 1
    fi

    if [ -z "${1}" ]; then
        return 1
    fi

    if which rpm 1>/dev/null 2>&1; then
        if rpm -q --quiet "${1}"; then
            return 0
        else
            return 1
        fi
    elif which dpkg-query 1>/dev/null 2>&1; then
        if dpkg-query -W "${1}" 1>/dev/null 2>&1; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

extract_archive() {
    if [ "${#}" -ne 1 ]; then
        return 1
    fi

    if [ ! -f "${1}" ]; then
        return 1
    fi

    echo "[Utility] Extracting archive ${1}"
    tar -xf "${1}" --no-same-owner

    return 0
}

apply_patch_to_directory() {
    if [ "${#}" -lt 2 ]; then
        return 1
    fi

    if ! which git 1>/dev/null 2>&1; then
        return 1
    fi

    for d in "${@}"; do
        :
    done

    if [ ! -d "${d}" ]; then
        unset -v d

        return 1
    fi

    while [ "${1}" != "${d}" ]; do
        if [ -f "${1}" ] && git -C "${d}" apply --check "${1}" 1>/dev/null 2>&1; then
            echo "[Utility] Applying patch ${1} to directory ${d}"
            git -C "${d}" apply "${1}"
        else
            unset -v d

            return 1
        fi

        shift
    done

    unset -v d

    return 0
}

stage_build_directory() {
    if [ "${#}" -eq 1 ]; then
        sd="${1}"
        bd="${1}-build"
    elif [ "${#}" -eq 2 ]; then
        sd="${1}"
        bd="${2}-build"
    else
        return 1
    fi

    if [ ! -d "${sd}" ]; then
        unset -v bd sd

        return 1
    fi

    echo "[Utility] Staging build directory for ${sd} at ${bd}"

    rm -f -r source
    ln -s "${sd}" source

    rm -f -r "${bd}"
    mkdir -p "${bd}"

    pushd "${bd}"

    unset -v bd sd

    return 0
}

patch_libtool_to_disable_rpath() {
    if [ ! -f libtool ]; then
        return 1
    fi

    # https://docs.fedoraproject.org/en-US/packaging-guidelines/#_beware_of_rpath
    echo "[Utility] Patching libtool to disable rpath"
    sed -i 's|^hardcode_libdir_flag_spec=.*|hardcode_libdir_flag_spec=""|g' libtool
    sed -i 's|^runpath_var=LD_RUN_PATH|runpath_var=DIE_RPATH_DIE|g' libtool

    return 0
}

make_compile() {
    make -j "$(getconf _NPROCESSORS_ONLN)" "${@}"

    return 0
}

make_install() {
    make install "${@}"

    return 0
}

remove_documentation_from_directory() {
    if [ "${#}" -lt 1 ]; then
        return 1
    fi

    for d in "${@}"; do
        if [ ! -d "${d}" ]; then
            continue
        fi

        echo "[Utility] Removing documentation from directory ${d}"

        rm -f -r -v "${d}/share/doc"
        rm -f -r -v "${d}/share/man"

        set -- "${d}/share/"*

        if [ "${1}" = "${d}/share/*" ]; then
            rm -f -r -v "${d}/share"
        fi
    done

    unset -v d

    return 0
}

remove_libtool_archive_from_directory() {
    if [ "${#}" -lt 1 ]; then
        return 1
    fi

    for d in "${@}"; do
        if [ ! -d "${d}" ]; then
            continue
        fi

        echo "[Utility] Removing libtool archive from directory ${d}"
        find "${d}" -name "*.la" -type f -print -delete
        find "${d}" -name "*.la" -type l -print -delete
    done

    unset -v d

    return 0
}

remove_pkgconfig_from_directory() {
    if [ "${#}" -lt 1 ]; then
        return 1
    fi

    for d in "${@}"; do
        if [ ! -d "${d}" ]; then
            continue
        fi

        echo "[Utility] Removing pkgconfig from directory ${d}"
        find "${d}" -depth -name "*pkgconfig*" -type d -print -execdir rm -fr "{}" ";"
        find "${d}" -depth -name "*pkgconfig*" -type l -print -execdir rm -fr "{}" ";"
    done

    unset -v d

    return 0
}

remove_static_library_from_directory() {
    if [ "${#}" -lt 1 ]; then
        return 1
    fi

    for d in "${@}"; do
        if [ ! -d "${d}" ]; then
            continue
        fi

        echo "[Utility] Removing static library from directory ${d}"
        find "${d}" -name "*.a" -type f -print -delete
        find "${d}" -name "*.a" -type l -print -delete
    done

    unset -v d

    return 0
}

patch_binary_to_set_rpath() {
    if [ "${#}" -lt 2 ]; then
        return 1
    fi

    if ! which patchelf readelf 1>/dev/null 2>&1; then
        return 1
    fi

    for r in "${@}"; do
        :
    done

    if [ ! -z "${r}" ]; then
        printf "%s\n" "${r}" | tr ":" "\n" | while IFS="" read -r d; do
            case "${d}" in
                '$LIB'*|'$ORIGIN'*)
                    continue
                    ;;
                *)
                    if [ ! -d "${d}" ]; then
                        unset -v d

                        return 1
                    fi
                    ;;
            esac
        done

        unset -v d
    fi

    while [ "${1}" != "${r}" ]; do
        if [ ! -f "${1}" ] || [ -L "${1}" ]; then
            shift

            continue
        fi

        if ! readelf -h "${1}" 1>/dev/null 2>&1; then
            shift

            continue
        fi

        if ! readelf -h "${1}" | grep -E -q "Type: +(DYN|EXEC)"; then
            shift

            continue
        fi

        if [ -z "${r}" ]; then
            echo "[Utility] Patching ${1} to remove rpath"
            patchelf --remove-rpath "${1}"
        else
            echo "[Utility] Patching ${1} to set rpath to ${r}"
            patchelf --force-rpath --set-rpath "${r}" "${1}"
        fi

        shift
    done

    unset -v r

    return 0
}

get_milestone() {
    if [ "${#}" -ne 1 ]; then
        return 1
    fi

    if [ -f "milestone-${1}" ]; then
        return 0
    else
        return 1
    fi
}

set_milestone() {
    if [ "${#}" -ne 1 ]; then
        return 1
    fi

    echo "Completed at $(date -u "+%FT%TZ")" > "milestone-${1}"

    return 0
}

prepend_ld_library_path() {
    if [ "${#}" -ne 1 ]; then
        return 1
    fi

    printf "%s\n" "${1}" | tr ":" "\n" | while IFS="" read -r d; do
        if [ ! -d "${d}" ]; then
            unset -v d

            return 1
        fi
    done

    unset -v d

    LD_LIBRARY_PATH_SAVE="${LD_LIBRARY_PATH:-}"

    export LD_LIBRARY_PATH="${1}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

    echo "[Utility] LD_LIBRARY_PATH set to: ${LD_LIBRARY_PATH}"

    return 0
}

restore_ld_library_path() {
    export LD_LIBRARY_PATH="${LD_LIBRARY_PATH_SAVE:-}"

    unset -v LD_LIBRARY_PATH_SAVE

    echo "[Utility] LD_LIBRARY_PATH set to: ${LD_LIBRARY_PATH}"

    return 0
}
