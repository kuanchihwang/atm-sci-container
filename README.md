# atm-sci-container

* [atm-sci-container](#atm-sci-container)
  * [Quick Start](#quick-start)
    * [CESM](#cesm)
    * [MPAS](#mpas)
    * [WRF](#wrf)
  * [Container Registries](#container-registries)
  * [Container Image Variants and Tags](#container-image-variants-and-tags)
  * [Usage](#usage)
  * [Included Software Stack](#included-software-stack)
  * [Included Device Drivers](#included-device-drivers)
  * [Supported Transports](#supported-transports)
  * [Building from Source](#building-from-source)

> [!NOTE]
> This `README.md` is a work in progress. More information to come soon...

High-performance computing (HPC) containers for parallel workloads (e.g., MPI, OpenMP), delivering portability, reproducibility, and optimal single-/multi-node performance out of the box.

For an overview of why containers remain valuable even for HPC scenarios, see the [Apptainer introduction](https://apptainer.org/docs/user/latest/introduction.html).

## Quick Start

### CESM

In this walkthrough, we will configure [CAM-SIMA](https://github.com/ESCOMP/CAM-SIMA) with MPAS dynamical core, a global 480-km mesh, Kessler microphysics, and the moist baroclinic wave initial condition. CAM-SIMA is a component model of [CESM](https://github.com/ESCOMP/CESM). The model will be built and run with GNU compilers version 15 and MPICH version 4.

Pull the appropriate container image and create a container from it.

```shell
docker image pull "docker.io/kuanchihwang/atm-sci-container:latest_gnu-15_mpich-4"
docker container run -it --rm \
    --env "CONTAINER_PRESET=cesm" \
    --volume "working:/working" \
    "docker.io/kuanchihwang/atm-sci-container:latest_gnu-15_mpich-4"
```

You are now in an interactive shell session inside the created container. Continue on:

```shell
# Set up git user name and email because CIME demands that you have them...
git config --global user.name "Insider"
git config --global user.email "insider@atm-sci-container"

# Download model input data.
mkdir -pv "/working/cesm-data-root/inputdata/atm/cam/chem/trop_mozart/ub"
wget -P "/working/cesm-data-root/inputdata/atm/cam/chem/trop_mozart/ub" \
    "https://osdf-director.osg-htc.org/ncar/gdex/d651077/cesmdata/inputdata/atm/cam/chem/trop_mozart/ub/clim_p_trop.nc"
mkdir -pv "/working/cesm-data-root/inputdata/atm/cam/inic/mpas"
wget -P "/working/cesm-data-root/inputdata/atm/cam/inic/mpas" \
    "https://osdf-director.osg-htc.org/ncar/gdex/d651077/cesmdata/inputdata/atm/cam/inic/mpas/mpasa480_L32_notopo_coords_c240507.nc"
wget -P "/working/cesm-data-root/inputdata/atm/cam/inic/mpas" \
    "https://osdf-director.osg-htc.org/ncar/gdex/d651077/cesmdata/inputdata/atm/cam/inic/mpas/mpasa480.graph.info"
wget -P "/working/cesm-data-root/inputdata/atm/cam/inic/mpas" \
    "https://osdf-director.osg-htc.org/ncar/gdex/d651077/cesmdata/inputdata/atm/cam/inic/mpas/mpasa480.graph.info.part.4"
# These should not be needed, but CIME wants them anyway...
mkdir -pv "/working/cesm-data-root/inputdata/share/meshes"
wget -P "/working/cesm-data-root/inputdata/share/meshes" \
    "https://osdf-director.osg-htc.org/ncar/gdex/d651077/cesmdata/inputdata/share/meshes/gx1v7_151008_ESMFmesh.nc"
wget -P "/working/cesm-data-root/inputdata/share/meshes" \
    "https://osdf-director.osg-htc.org/ncar/gdex/d651077/cesmdata/inputdata/share/meshes/mpasa480_ESMFmesh-211109.nc"

# Clone model source code.
git clone --branch development --depth 1 "https://github.com/ESCOMP/CAM-SIMA.git"
cd CAM-SIMA
./bin/git-fleximod update
cd ..

# Copy model configuration files.
cp -av /usr/local/share/cesm-config/atm-sci-container CAM-SIMA/ccs_config/machines

# Configure model.
# Normally, `CESM_NTASKS_PER_NODE` is auto-detected at the container entrypoint.
# For this walkthrough, we override it for simplicity.
export CESM_NTASKS_PER_NODE="4"
./CAM-SIMA/cime/scripts/create_newcase \
    --machine atm-sci-container \
    --compiler gnu \
    --mpilib mpich \
    --case /working/cesm-case-root/cam-sima-development \
    --compset FKESSLER \
    --res mpasa480_mpasa480 \
    --run-unsupported
cd /working/cesm-case-root/cam-sima-development
./case.setup
cat > user_nl_cam << EOF
debug_output = 3
hist_add_inst_fields;h0: U,V,T,Q,PMID
hist_file_type;h0: history
hist_max_frames;h0: 24
hist_output_frequency;h0: hours
hist_write_nstep0;h0: .true.
EOF

# Build model.
./case.build
# Run model, which only takes about half a minute to complete.
./case.submit

# Examine model logs and history output.
cd /working/cesm-output-root/archive/cam-sima-development
# Model logs are located in the `logs` directory.
ls -l logs
# Model history output is located in the `atm/hist` directory.
ls -l atm/hist
```

Congratulations! You just built CAM-SIMA and ran a test case on your own system with little effort.

Traditionally, porting CESM and its component models like CAM-SIMA to a new system requires substantial effort. Its notoriously difficult dependency stack certainly does not help reduce the barrier to entry. In contrast, with `atm-sci-container`, standard CAM-SIMA dependencies are already included, and the container entrypoint takes care of the environment setup for you. There is no need to mess with any packages or environment variables at all. Hooray!

If multi-node execution and optimal performance are desired, it is recommended that you use [Apptainer](https://apptainer.org). Specifically, refer to the "Hybrid model" section of this [Apptainer documentation](https://apptainer.org/docs/user/latest/mpi.html) for details.

### MPAS

In this walkthrough, we will build [MPAS](https://github.com/MPAS-Dev/MPAS-Model) with Intel compilers version 2025 and Open MPI version 5.

Pull the appropriate container image and create a container from it.

```shell
docker image pull "docker.io/kuanchihwang/atm-sci-container:latest_intel-2025_open-mpi-5"
docker container run -it --rm \
    --env "CONTAINER_PRESET=mpas" \
    --volume "working:/working" \
    "docker.io/kuanchihwang/atm-sci-container:latest_intel-2025_open-mpi-5"
```

You are now in an interactive shell session inside the created container. Continue on:

```shell
# Clone model source code.
git clone --branch develop --depth 1 "https://github.com/MPAS-Dev/MPAS-Model.git"

# Build model.
cd MPAS-Model
make intel CORE="init_atmosphere"
make intel CORE="atmosphere"
# You should find that model executables like `init_atmosphere_model`, `atmosphere_model`, etc. have been generated.
ls -l
```

You can now run the model as you normally would. Yes, it is really that easy. With `atm-sci-container`, standard MPAS dependencies are already included, and the container entrypoint takes care of the environment setup for you. There is no need to mess with any packages or environment variables at all. Hooray!

If multi-node execution and optimal performance are desired, it is recommended that you use [Apptainer](https://apptainer.org). Specifically, refer to the "Hybrid model" section of this [Apptainer documentation](https://apptainer.org/docs/user/latest/mpi.html) for details.

### WRF

In this walkthrough, we will build [WRF](https://github.com/wrf-model/WRF) with Intel compilers version 2024 and Open MPI version 4.

Pull the appropriate container image and create a container from it.

```shell
docker image pull "docker.io/kuanchihwang/atm-sci-container:latest_intel-2024_open-mpi-4"
docker container run -it --rm \
    --env "CONTAINER_PRESET=wrf" \
    --volume "working:/working" \
    "docker.io/kuanchihwang/atm-sci-container:latest_intel-2024_open-mpi-4"
```

You are now in an interactive shell session inside the created container. Continue on:

```shell
# Clone model source code.
git clone --branch v4.7.1 --depth 1 "https://github.com/wrf-model/WRF.git"
cd WRF
git submodule update --init --recursive
cd ..
git clone --branch v4.6.0 --depth 1 "https://github.com/wrf-model/WPS.git"
cd WPS
# WPS demands a very narrow JasPer version range, which is completely unreasonable. Relax it a bit.
sed -e "s/1.900.1...1.900.29/1.900.1...2.0.33/g" -i CMakeLists.txt
cd ..

# Build WRF.
cd WRF
# When asked about the build configuration, be sure to choose the one similar to "... Intel (ifx/icx) ...".
# For others, feel free to choose whatever you would like.
./configure_new
./compile_new
# You should find that model executables like `real`, `wrf`, etc. have been generated.
ls -l install/bin

# Build WPS.
cd ../WPS
# When asked about the build configuration, be sure to choose the one similar to "... Intel (ifx/icx) ...".
# For others, feel free to choose whatever you would like.
./configure_new
./compile_new
# You should find that model executables like `geogrid`, `ungrib`, `metgrid`, etc. have been generated.
ls -l install/bin
```

You can now run the model as you normally would. Yes, again, it is really that easy. With `atm-sci-container`, standard WRF dependencies are already included, and the container entrypoint takes care of the environment setup for you. There is no need to mess with any packages or environment variables at all. Hooray!

If multi-node execution and optimal performance are desired, it is recommended that you use [Apptainer](https://apptainer.org). Specifically, refer to the "Hybrid model" section of this [Apptainer documentation](https://apptainer.org/docs/user/latest/mpi.html) for details.

## Container Registries

Prebuilt container images are available and can be pulled from:

* [Docker Hub - hpc-container](https://hub.docker.com/r/kuanchihwang/hpc-container)
* [Docker Hub - atm-sci-container](https://hub.docker.com/r/kuanchihwang/atm-sci-container)
* [GitHub Container Registry - hpc-container](https://github.com/users/kuanchihwang/packages/container/package/hpc-container)
* [GitHub Container Registry - atm-sci-container](https://github.com/users/kuanchihwang/packages/container/package/atm-sci-container)

## Container Image Variants and Tags

The container images are available in **2** variants:

1. `hpc-container`: A general-purpose HPC container image suitable for parallel workloads (e.g., MPI, OpenMP). It includes everything listed in the "[Included Software Stack](#included-software-stack)" section, except for libraries that are commonly used by atmospheric models.
2. `atm-sci-container`: A specialized HPC container image tailored for atmospheric science applications. Built upon `hpc-container`, it includes additional libraries that are commonly used by atmospheric models such as CESM, MPAS, and WRF.

Both variants are tagged in the `${VERSION}_${COMPILER}_${MPI}` format, where:

* `${VERSION}` indicates the version of the container image. It should correspond to a Git tag in this project, or `latest`.
* `${COMPILER}` indicates the compiler toolchain available in the container image. It should be one of `gnu-11`, `gnu-12`, `gnu-13`, `gnu-14`, `gnu-15`, `intel-2024`, or `intel-2025`.
* `${MPI}` indicates the MPI library available in the container image. It should be one of `mpich-4`, `open-mpi-4`, `open-mpi-5`, or `intel-mpi`.

For each variant and `${VERSION}`, there are currently **23** combinations of compiler toolchains and MPI libraries available.

## Usage

WIP...

## Included Software Stack

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./README-Container-Software-Stack-Dark.svg">
  <source media="(prefers-color-scheme: light)" srcset="./README-Container-Software-Stack-Light.svg">
  <img alt="Container Software Stack" src="./README-Container-Software-Stack-Light.svg">
</picture>

* AlmaLinux Base Image 9.7
* Infrastructural Libraries
  * zlib 1.3.2
  * numactl (Distribution version)
  * hwloc 2.12.2
  * libevent (Distribution version)
  * PMI2 from Slurm 24.11.7
  * PMIx 5.0.10
  * PRRTE 3.0.13
* Communication Libraries
  * UCX 1.19.1
  * libfabric 2.4.0
* Compilers
  * GNU Compiler Collection 11 (C, C++, Fortran)
  * GNU Compiler Collection 12 (C, C++, Fortran)
  * GNU Compiler Collection 13 (C, C++, Fortran)
  * GNU Compiler Collection 14 (C, C++, Fortran)
  * GNU Compiler Collection 15 (C, C++, Fortran)
  * Intel oneAPI Compiler 2024.2.1 (C, C++, Fortran)
  * Intel oneAPI Compiler 2025.3.3 (C, C++, Fortran)
* MPI Libraries
  * MPICH 4.3.2
  * Open MPI 4.1.8
  * Open MPI 5.0.10
  * Intel MPI 2021.13.1 (Only when paired with Intel oneAPI Compiler 2024.2.1)
  * Intel MPI 2021.17.2 (Only when paired with Intel oneAPI Compiler 2025.3.3)
* Libraries
  * libaec 1.1.6
  * zlib 1.3.2
  * zstd 1.5.7
  * libjpeg 9f
  * JasPer 2.0.33
  * libpng 1.6.56
  * HDF5 1.14.6
    * Serial mode
    * Parallel mode
  * PNetCDF 1.14.1
  * NetCDF-C 4.9.3
    * Classic data model, Serial mode
    * Enhanced data model, Serial mode
    * Enhanced data model, Parallel mode
  * NetCDF-Fortran 4.6.2
    * Classic data model, Serial mode
    * Enhanced data model, Serial mode
    * Enhanced data model, Parallel mode
  * ParallelIO 2.6.8
  * Netlib LAPACK 3.12.1
  * ESMF 8.9.1
  * pFUnit 4.16.0

## Included Device Drivers

The user-space drivers for the following devices are included in the container images.

* Cornelis Omni-Path Express Software 12.1.0.1.4
* HPE Slingshot Host Software 12.0.2
* Intel Ethernet Fabric Suite 12.1.0.1.6
* NVIDIA DOCA 2.9.4

They provide hardware enablement for their respective HPC network interconnects, described in the "[Supported Transports](#supported-transports)" section.

## Supported Transports

The following high-speed and low-latency transports are supported by the container images. At run time, if the matching kernel-space drivers and the actual hardware are present, optimal MPI communication performance can be achieved out of the box.

* Intra-node Communication via Linux Kernel Features
  * Cross Memory Attach (CMA)
  * Cross Process Memory Mapping (XPMEM)
  * Kernel Nemesis (KNEM)
* Inter-node Communication via HPC Network Interconnects
  * AWS Elastic Fabric Adapter
  * Cornelis Omni-Path NIC
  * HPE Slingshot 11 NIC
  * Intel Ethernet 800 NIC
  * NVIDIA ConnectX InfiniBand NIC

Please refer to the vendor documentation for the exact list of supported hardware.

## Building from Source

To build the container images from source, use the `Containerfile` directly or use the `Makefile` for convenience. You must be running an x86-64 Linux system with either `docker` or `podman` installed. If both are available, `docker` takes precedence. The supported system architecture is constrained by the included device drivers, not by this project.

1. Pull the base and data container images.

    ```shell
    make stage
    ```

2. Build container images by specifying the desired combination of `VERSION`, `COMPILER`, and `MPI`, one at a time. See the "[Container Image Variants and Tags](#container-image-variants-and-tags)" section for details. The `build-hpc` target builds the `hpc-container` variant, the `build-atm-sci` target builds the `atm-sci-container` variant, and the `build` target builds both.

    ```shell
    make build [VERSION=...] [COMPILER=...] [MPI=...]
    make build-hpc [VERSION=...] [COMPILER=...] [MPI=...]
    make build-atm-sci [VERSION=...] [COMPILER=...] [MPI=...]
    ```

3. Alternatively, simply run the `cicd/make-all.sh` shell script to build all possible combinations and variants in one pass. This can take several hours to complete.

4. Clean up built and dangling container images. The `clean-hpc` target cleans the `hpc-container` variant, the `clean-atm-sci` target cleans the `atm-sci-container` variant, and the `clean` target cleans both.

    ```shell
    make clean
    make clean-hpc
    make clean-atm-sci
    ```
