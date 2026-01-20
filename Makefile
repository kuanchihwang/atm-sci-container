VERSION ?= testing

# Compiler choices are:
# * gcc-11 (Default in RHEL 9)
# * gcc-12
# * gcc-13
# * gcc-14
# * gcc-15
# * intel-2024
# * intel-2025
COMPILER ?= gcc-11

# MPI choices are:
# * intel-mpi
# * mpich-4
# * open-mpi-4
# * open-mpi-5
MPI ?= open-mpi-5

DOCKER = $(shell which docker 1>/dev/null 2>&1 && echo docker || echo podman)
BASE_IMAGE_NAME = docker.io/almalinux/9-base
BASE_IMAGE_TAG = 9.7
IMAGE_NAME = localhost/atm-sci-container
IMAGE_TAG = $(VERSION)_$(COMPILER)_$(MPI)

.PHONY: all
all:
	@echo "Usage:"
	@echo "    make stage"
	@echo "    make build [VERSION=...] [COMPILER=...] [MPI=...]"
	@echo "    make clean"
	@echo "    make reset (Warning: Mass destruction!)"

.PHONY: stage
stage:
	@$(DOCKER) pull $(BASE_IMAGE_NAME):$(BASE_IMAGE_TAG)

.PHONY: build
build: build-hpc build-atm-sci-lib

.PHONY: build-hpc
build-hpc:
	@$(DOCKER) build \
		--build-arg BASE_IMAGE_NAME="$(BASE_IMAGE_NAME)" \
		--build-arg BASE_IMAGE_TAG="$(BASE_IMAGE_TAG)" \
		--build-arg COMPILER="$(COMPILER)" \
		--build-arg MPI="$(MPI)" \
		--file Containerfile.hpc \
		--tag "localhost/hpc-container:$(IMAGE_TAG)" .

.PHONY: build-atm-sci-lib
build-atm-sci-lib:
	@$(DOCKER) build \
		--build-arg BASE_IMAGE_NAME="localhost/hpc-container" \
		--build-arg BASE_IMAGE_TAG="$(IMAGE_TAG)" \
		--build-arg COMPILER="$(COMPILER)" \
		--build-arg MPI="$(MPI)" \
		--file Containerfile.atm-sci-lib \
		--tag "localhost/atm-sci-lib-container:$(IMAGE_TAG)" .

.PHONY: clean
clean: clean-hpc clean-atm-sci-lib

.PHONY: clean-hpc
clean-hpc:
	@for IMAGE in $$($(DOCKER) image ls -q "localhost/hpc-container"); do \
		$(DOCKER) image rm -f -i "$${IMAGE}"; \
	done

.PHONY: clean-atm-sci-lib
clean-atm-sci-lib:
	@for IMAGE in $$($(DOCKER) image ls -q "localhost/atm-sci-lib-container"); do \
		$(DOCKER) image rm -f -i "$${IMAGE}"; \
	done

.PHONY: deep-clean
deep-clean: clean
	@$(DOCKER) image prune --all --build-cache --external -f

.PHONY: reset
reset:
	@$(DOCKER) system reset -f
