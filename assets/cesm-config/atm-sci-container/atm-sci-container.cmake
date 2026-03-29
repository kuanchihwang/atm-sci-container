# The hacky logic below is copied from the upstream `ccs_config`. It is set on a "machine-by-machine" basis,
# so it needs to be duplicated here...

if (COMP_NAME STREQUAL "gptl")
    string(APPEND CPPDEFS " -DBIT64 -DHAVE_COMM_F2C -DHAVE_GETTIMEOFDAY -DHAVE_NANOTIME -DHAVE_SLASHPROC -DHAVE_TIMES")
endif()

string(APPEND CPPDEFS " -DHAVE_GETTID")

# The upstream `ccs_config` adds linker flags for Intel oneMKL by default, but it is not installed here.
# Forcefully remove it.

string(REGEX REPLACE " *-q?mkl[A-Za-z=]* *" " " SLIBS "${SLIBS}")

# The logic below is mirrored from the `set_selected_compiler` and `set_selected_mpi_compiler` functions
# in `scripts/utility-functions.sh`.
# Optimization flags are left out here because they are already set by the upstream `ccs_config`.

if("$ENV{COMPILER}" MATCHES "^gnu-[0-9]+$")
    set(SCC "gcc")
    string(APPEND CFLAGS " -fPIC -march=x86-64-v3 -mtune=znver3")
    set(SCXX "g++")
    string(APPEND CXXFLAGS " -fPIC -march=x86-64-v3 -mtune=znver3")
    set(SFC "gfortran")
    string(APPEND FFLAGS " -fPIC -march=x86-64-v3 -mtune=znver3")
elseif("$ENV{COMPILER}" STREQUAL "intel-2024")
    set(SCC "icx")
    string(APPEND CFLAGS " -fpic -march=core-avx2 -mtune=core-avx2")
    set(SCXX "icpx")
    string(APPEND CXXFLAGS " -fpic -march=core-avx2 -mtune=core-avx2")
    set(SFC "ifort")
    string(APPEND FFLAGS " -fpic -march=core-avx2 -mtune=core-avx2 -Qoption,fpp,\"-macro_expand=vc\"")
elseif("$ENV{COMPILER}" STREQUAL "intel-2025")
    set(SCC "icx")
    string(APPEND CFLAGS " -fpic -march=core-avx2 -mtune=core-avx2")
    set(SCXX "icpx")
    string(APPEND CXXFLAGS " -fpic -march=core-avx2 -mtune=core-avx2")
    set(SFC "ifx")
    string(APPEND FFLAGS " -fpic -march=core-avx2 -mtune=core-avx2 -Qoption,fpp,\"-macro_expand=vc\"")
else()
    message(FATAL_ERROR "Failed to set compilers in atm-sci-container.cmake")
endif()

if("$ENV{MPI}" STREQUAL "intel-mpi")
    if("$ENV{COMPILER}" STREQUAL "intel-2024")
        set(MPICC "mpiicx")
        set(MPICXX "mpiicpx")
        set(MPIFC "mpiifort")
    elseif("$ENV{COMPILER}" STREQUAL "intel-2025")
        set(MPICC "mpiicx")
        set(MPICXX "mpiicpx")
        set(MPIFC "mpiifx")
    else()
        message(FATAL_ERROR "Failed to set MPI compilers in atm-sci-container.cmake")
    endif()
elseif("$ENV{MPI}" MATCHES "^mpich-[0-9]+$")
    set(MPICC "mpicc")
    set(MPICXX "mpic++")
    set(MPIFC "mpifort")
elseif("$ENV{MPI}" MATCHES "^open-mpi-[0-9]+$")
    set(MPICC "mpicc")
    set(MPICXX "mpic++")
    set(MPIFC "mpifort")
else()
    message(FATAL_ERROR "Failed to set MPI compilers in atm-sci-container.cmake")
endif()

string(REGEX REPLACE " +" " " CFLAGS "${CFLAGS}")
string(REGEX REPLACE " +" " " CXXFLAGS "${CXXFLAGS}")
string(REGEX REPLACE " +" " " CPPDEFS "${CPPDEFS}")
string(REGEX REPLACE " +" " " FFLAGS "${FFLAGS}")
