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

BASE_IMAGE_NAME ?= docker.io/almalinux/9-base
BASE_IMAGE_TAG ?= 9.7
DATA_IMAGE_NAME ?= docker.io/kuanchihwang/atm-sci-container-data
DATA_IMAGE_TAG ?= 2026-01-29

DOCKER = $(shell which docker 1>/dev/null 2>&1 && echo docker || echo podman)
IMAGE_NAME = atm-sci-container
IMAGE_TAG = $(VERSION)_$(COMPILER)_$(MPI)

.NOTPARALLEL:

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
	@$(DOCKER) pull $(DATA_IMAGE_NAME):$(DATA_IMAGE_TAG)

.PHONY: build
build: build-hpc build-atm-sci

.PHONY: build-hpc
build-hpc:
	@$(DOCKER) build \
		--build-arg BASE_IMAGE_NAME="$(BASE_IMAGE_NAME)" \
		--build-arg BASE_IMAGE_TAG="$(BASE_IMAGE_TAG)" \
		--build-arg DATA_IMAGE_NAME="$(DATA_IMAGE_NAME)" \
		--build-arg DATA_IMAGE_TAG="$(DATA_IMAGE_TAG)" \
		--build-arg COMPILER="$(COMPILER)" \
		--build-arg MPI="$(MPI)" \
		--file Containerfile.hpc \
		--label "org.opencontainers.image.revision=$(shell git rev-parse --verify HEAD)" \
		--label "org.opencontainers.image.version=$(VERSION)" \
		--tag "localhost/build-artifact/hpc-container:$(IMAGE_TAG)" .

.PHONY: build-atm-sci
build-atm-sci:
	@$(DOCKER) build \
		--build-arg BASE_IMAGE_NAME="localhost/build-artifact/hpc-container" \
		--build-arg BASE_IMAGE_TAG="$(IMAGE_TAG)" \
		--build-arg DATA_IMAGE_NAME="$(DATA_IMAGE_NAME)" \
		--build-arg DATA_IMAGE_TAG="$(DATA_IMAGE_TAG)" \
		--build-arg COMPILER="$(COMPILER)" \
		--build-arg MPI="$(MPI)" \
		--file Containerfile.atm-sci \
		--label "org.opencontainers.image.revision=$(shell git rev-parse --verify HEAD)" \
		--label "org.opencontainers.image.version=$(VERSION)" \
		--tag "localhost/build-artifact/atm-sci-container:$(IMAGE_TAG)" .

.PHONY: clean
clean: clean-hpc clean-atm-sci

.PHONY: clean-hpc
clean-hpc:
	@for IMAGE in $$($(DOCKER) image ls -q "hpc-container"); do \
		$(DOCKER) image rm -f -i "$${IMAGE}"; \
	done

.PHONY: clean-atm-sci
clean-atm-sci:
	@for IMAGE in $$($(DOCKER) image ls -q "atm-sci-container"); do \
		$(DOCKER) image rm -f -i "$${IMAGE}"; \
	done

.PHONY: deep-clean
deep-clean: clean
	@$(DOCKER) image prune --all --build-cache --external -f

.PHONY: reset
reset:
	@$(DOCKER) system reset -f
