REGISTRY ?= docker.io
NAMESPACE ?= kuanchihwang
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
DATA_IMAGE_TAG ?= 2026-02-21

DOCKER = $(shell which docker 1>/dev/null 2>&1 && echo docker || echo podman)
HPC_IMAGE_NAME = hpc-container
ATM_SCI_IMAGE_NAME = atm-sci-container
IMAGE_TAG = $(VERSION)_$(COMPILER)_$(MPI)

.NOTPARALLEL:

.PHONY: all
all:
	@echo "Usage:"
	@echo "    make stage"
	@echo "    make build [VERSION=...] [COMPILER=...] [MPI=...]"
	@echo "    make clean"
	@echo ""
	@echo "    make login [REGISTRY=...] [NAMESPACE=...]"
	@echo "    make push [REGISTRY=...] [NAMESPACE=...] [VERSION=...] [COMPILER=...] [MPI=...]"
	@echo "    make logout [REGISTRY=...]"
	@echo ""
	@echo "    make reset (Warning: Mass destruction!)"

.PHONY: stage
stage:
	@$(DOCKER) image pull $(BASE_IMAGE_NAME):$(BASE_IMAGE_TAG)
	@$(DOCKER) image pull $(DATA_IMAGE_NAME):$(DATA_IMAGE_TAG)

.PHONY: build
build: build-hpc build-atm-sci

.PHONY: build-hpc
build-hpc:
	@$(DOCKER) image build \
		--build-arg BASE_IMAGE_NAME="$(BASE_IMAGE_NAME)" \
		--build-arg BASE_IMAGE_TAG="$(BASE_IMAGE_TAG)" \
		--build-arg DATA_IMAGE_NAME="$(DATA_IMAGE_NAME)" \
		--build-arg DATA_IMAGE_TAG="$(DATA_IMAGE_TAG)" \
		--build-arg COMPILER="$(COMPILER)" \
		--build-arg MPI="$(MPI)" \
		--file Containerfile.hpc \
		--label "org.opencontainers.image.revision=$(shell git rev-parse --verify HEAD)" \
		--label "org.opencontainers.image.version=$(VERSION)" \
		--tag "localhost/build-artifact/$(HPC_IMAGE_NAME):$(IMAGE_TAG)" .

.PHONY: build-atm-sci
build-atm-sci:
	@$(DOCKER) image build \
		--build-arg BASE_IMAGE_NAME="localhost/build-artifact/$(HPC_IMAGE_NAME)" \
		--build-arg BASE_IMAGE_TAG="$(IMAGE_TAG)" \
		--build-arg DATA_IMAGE_NAME="$(DATA_IMAGE_NAME)" \
		--build-arg DATA_IMAGE_TAG="$(DATA_IMAGE_TAG)" \
		--build-arg COMPILER="$(COMPILER)" \
		--build-arg MPI="$(MPI)" \
		--file Containerfile.atm-sci \
		--label "org.opencontainers.image.revision=$(shell git rev-parse --verify HEAD)" \
		--label "org.opencontainers.image.version=$(VERSION)" \
		--tag "localhost/build-artifact/$(ATM_SCI_IMAGE_NAME):$(IMAGE_TAG)" .

.PHONY: push
push: push-hpc push-atm-sci

.PHONY: push-hpc
push-hpc:
	@$(DOCKER) image tag "localhost/build-artifact/$(HPC_IMAGE_NAME):$(IMAGE_TAG)" "$(REGISTRY)/$(NAMESPACE)/$(HPC_IMAGE_NAME):$(IMAGE_TAG)"
	@$(DOCKER) image tag "localhost/build-artifact/$(HPC_IMAGE_NAME):$(IMAGE_TAG)" "$(REGISTRY)/$(NAMESPACE)/$(HPC_IMAGE_NAME):latest"
	@$(DOCKER) image push "$(REGISTRY)/$(NAMESPACE)/$(HPC_IMAGE_NAME):$(IMAGE_TAG)"
	@$(DOCKER) image push "$(REGISTRY)/$(NAMESPACE)/$(HPC_IMAGE_NAME):latest"

.PHONY: push-atm-sci
push-atm-sci:
	@$(DOCKER) image tag "localhost/build-artifact/$(ATM_SCI_IMAGE_NAME):$(IMAGE_TAG)" "$(REGISTRY)/$(NAMESPACE)/$(ATM_SCI_IMAGE_NAME):$(IMAGE_TAG)"
	@$(DOCKER) image tag "localhost/build-artifact/$(ATM_SCI_IMAGE_NAME):$(IMAGE_TAG)" "$(REGISTRY)/$(NAMESPACE)/$(ATM_SCI_IMAGE_NAME):latest"
	@$(DOCKER) image push "$(REGISTRY)/$(NAMESPACE)/$(ATM_SCI_IMAGE_NAME):$(IMAGE_TAG)"
	@$(DOCKER) image push "$(REGISTRY)/$(NAMESPACE)/$(ATM_SCI_IMAGE_NAME):latest"

.PHONY: login
login:
	@$(DOCKER) login --username "$(NAMESPACE)" "$(REGISTRY)"

.PHONY: logout
logout:
	@$(DOCKER) logout "$(REGISTRY)"

.PHONY: clean
clean: clean-hpc clean-atm-sci

.PHONY: clean-hpc
clean-hpc:
	@for IMAGE in $$($(DOCKER) image ls -q "$(HPC_IMAGE_NAME)"); do \
		$(DOCKER) image rm -f -i "$${IMAGE}"; \
	done
	@for IMAGE in $$($(DOCKER) image ls -q --filter "dangling=true"); do \
		$(DOCKER) image rm -f -i "$${IMAGE}"; \
	done

.PHONY: clean-atm-sci
clean-atm-sci:
	@for IMAGE in $$($(DOCKER) image ls -q "$(ATM_SCI_IMAGE_NAME)"); do \
		$(DOCKER) image rm -f -i "$${IMAGE}"; \
	done
	@for IMAGE in $$($(DOCKER) image ls -q --filter "dangling=true"); do \
		$(DOCKER) image rm -f -i "$${IMAGE}"; \
	done

.PHONY: deep-clean
deep-clean: clean
	@$(DOCKER) image prune --all --build-cache --external -f

.PHONY: reset
reset:
	@$(DOCKER) system reset -f
