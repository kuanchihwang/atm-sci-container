#!/bin/sh
set -euo pipefail

COMPILER_SPECIFIC_LIBRARY_PATH="/opt/hpc/compiler/${COMPILER}"
MPI_SPECIFIC_LIBRARY_PATH="/opt/hpc/mpi/${COMPILER}/${MPI}"

CONTAINER_PRESET="${CONTAINER_PRESET:-}"

case "${CONTAINER_PRESET}" in
    cesm)
        # TODO...
        :
        ;;
    mpas)
        CONTAINER_ENVIRONMENT="base+pnetcdf3+phdf5+pnetcdf4+pio${CONTAINER_ENVIRONMENT:++$CONTAINER_ENVIRONMENT}"

        export PNETCDF="${MPI_SPECIFIC_LIBRARY_PATH}/pnetcdf3"
        export NETCDF="${MPI_SPECIFIC_LIBRARY_PATH}/pnetcdf4"
        export PIO="${MPI_SPECIFIC_LIBRARY_PATH}/pio"
        ;;
    wrf)
        CONTAINER_ENVIRONMENT="base+hdf5+netcdf4${CONTAINER_ENVIRONMENT:++$CONTAINER_ENVIRONMENT}"
        # CONTAINER_ENVIRONMENT="base+pnetcdf3+phdf5+pnetcdf4${CONTAINER_ENVIRONMENT:++$CONTAINER_ENVIRONMENT}"

        export JASPERINC="${COMPILER_SPECIFIC_LIBRARY_PATH}/base/include"
        export JASPERLIB="${COMPILER_SPECIFIC_LIBRARY_PATH}/base/lib"
        export HDF5="${COMPILER_SPECIFIC_LIBRARY_PATH}/hdf5"
        export NETCDF="${COMPILER_SPECIFIC_LIBRARY_PATH}/netcdf4"
        # export PNETCDF="${MPI_SPECIFIC_LIBRARY_PATH}/pnetcdf3"
        # export PHDF5="${MPI_SPECIFIC_LIBRARY_PATH}/phdf5"
        # export NETCDFPAR="${MPI_SPECIFIC_LIBRARY_PATH}/pnetcdf4"

        export WRFIO_NCD_NO_LARGE_FILE_SUPPORT="0"
        ;;
    *)
        # No or unsupported preset is specified. Nothing to do.
        :
        ;;
esac

CONTAINER_ENVIRONMENT="${CONTAINER_ENVIRONMENT:-}"

while IFS="" read -r x; do
    case "${x}" in
        base)
            export LD_LIBRARY_PATH="/usr/lib64:${COMPILER_SPECIFIC_LIBRARY_PATH}/base/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            export PATH="${COMPILER_SPECIFIC_LIBRARY_PATH}/base/bin${PATH:+:$PATH}"
            ;;
        hdf5)
            export LD_LIBRARY_PATH="${COMPILER_SPECIFIC_LIBRARY_PATH}/hdf5/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            export PATH="${COMPILER_SPECIFIC_LIBRARY_PATH}/hdf5/bin${PATH:+:$PATH}"
            ;;
        lapack)
            export LD_LIBRARY_PATH="${COMPILER_SPECIFIC_LIBRARY_PATH}/lapack/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            ;;
        netcdf3)
            export LD_LIBRARY_PATH="${COMPILER_SPECIFIC_LIBRARY_PATH}/netcdf3/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            export PATH="${COMPILER_SPECIFIC_LIBRARY_PATH}/netcdf3/bin${PATH:+:$PATH}"
            ;;
        netcdf4)
            export LD_LIBRARY_PATH="${COMPILER_SPECIFIC_LIBRARY_PATH}/netcdf4/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            export PATH="${COMPILER_SPECIFIC_LIBRARY_PATH}/netcdf4/bin${PATH:+:$PATH}"
            ;;
        esmf)
            export LD_LIBRARY_PATH="$(dirname "$(find "${MPI_SPECIFIC_LIBRARY_PATH}/esmf/lib" -name "libesmf.so" -type f -print -quit)")${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            export PATH="$(dirname "$(find "${MPI_SPECIFIC_LIBRARY_PATH}/esmf/bin" -name "ESMF_PrintInfo" -type f -print -quit)")${PATH:+:$PATH}"

            export CMAKE_PREFIX_PATH="${MPI_SPECIFIC_LIBRARY_PATH}/esmf${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
            export ESMFMKFILE="$(find "${MPI_SPECIFIC_LIBRARY_PATH}/esmf/lib" -name "esmf.mk" -type f -print -quit)"
            ;;
        pfunit)
            export CMAKE_PREFIX_PATH="${MPI_SPECIFIC_LIBRARY_PATH}/pfunit${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
            ;;
        phdf5)
            export LD_LIBRARY_PATH="${MPI_SPECIFIC_LIBRARY_PATH}/phdf5/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            export PATH="${MPI_SPECIFIC_LIBRARY_PATH}/phdf5/bin${PATH:+:$PATH}"
            ;;
        pio)
            export LD_LIBRARY_PATH="${MPI_SPECIFIC_LIBRARY_PATH}/pio/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            ;;
        pnetcdf3)
            export LD_LIBRARY_PATH="${MPI_SPECIFIC_LIBRARY_PATH}/pnetcdf3/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            export PATH="${MPI_SPECIFIC_LIBRARY_PATH}/pnetcdf3/bin${PATH:+:$PATH}"
            ;;
        pnetcdf4)
            export LD_LIBRARY_PATH="${MPI_SPECIFIC_LIBRARY_PATH}/pnetcdf4/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            export PATH="${MPI_SPECIFIC_LIBRARY_PATH}/pnetcdf4/bin${PATH:+:$PATH}"
            ;;
        *)
            # No or unsupported environment is specified. Nothing to do.
            :
            ;;
    esac
done << EOF
$(printf "%s\n" "${CONTAINER_ENVIRONMENT}" | tr "+" "\n")
EOF

unset -v COMPILER_SPECIFIC_LIBRARY_PATH
unset -v MPI_SPECIFIC_LIBRARY_PATH
