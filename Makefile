DOCKER = $(shell command -v docker 1>/dev/null 2>&1 && echo docker || echo podman)
REGISTRY ?= docker.io
NAMESPACE ?= kuanchihwang

VERSION ?= testing

# Compiler choices are:
# * gnu-11 (Default in RHEL 9)
# * gnu-12
# * gnu-13
# * gnu-14 (Default in RHEL 10)
# * gnu-15
# * intel-2024
# * intel-2025
# * nvidia-2026
COMPILER ?= gnu-11

# MPI choices are:
# * mpich-4
# * mpich-5
# * open-mpi-4
# * open-mpi-5
# * intel-mpi
MPI ?= open-mpi-5

# GPU choices are:
# * cuda-12
# * cuda-13
# * none
GPU ?= none

BASE_IMAGE_NAME ?= docker.io/almalinux/9-base
BASE_IMAGE_TAG ?= 9.8
DATA_IMAGE_NAME ?= docker.io/kuanchihwang/atm-sci-container-data
BINARY_DATA_TAG ?= 2026-11-19_binary
SOURCE_DATA_TAG ?= 2026-11-19_source

HPC_IMAGE_NAME ?= localhost/build-artifact/hpc-container
HPC_IMAGE_TAG ?= $(VERSION)_$(COMPILER)_$(MPI)_$(GPU)
ATM_SCI_IMAGE_NAME ?= localhost/build-artifact/atm-sci-container
ATM_SCI_IMAGE_TAG ?= $(VERSION)_$(COMPILER)_$(MPI)_$(GPU)

.NOTPARALLEL:

.PHONY: all
all:
	@echo "Usage:"
	@echo "    make stage"
	@echo "    make build [VERSION=...] [COMPILER=...] [MPI=...] [GPU=...]"
	@echo "    make clean"
	@echo ""
	@echo "    make login [REGISTRY=...] [NAMESPACE=...]"
	@echo "    make push [REGISTRY=...] [NAMESPACE=...] [VERSION=...] [COMPILER=...] [MPI=...] [GPU=...]"
	@echo "    make logout [REGISTRY=...]"
	@echo ""
	@echo "    make reset (Warning: Mass destruction!)"

.PHONY: stage
stage:
	@$(DOCKER) image pull $(BASE_IMAGE_NAME):$(BASE_IMAGE_TAG)
	@$(DOCKER) image pull $(DATA_IMAGE_NAME):$(BINARY_DATA_TAG)
	@$(DOCKER) image pull $(DATA_IMAGE_NAME):$(SOURCE_DATA_TAG)

.PHONY: build
build: build-hpc build-atm-sci

.PHONY: build-hpc
build-hpc:
	@echo "[$$(date -u "+%FT%TZ")] Building $(HPC_IMAGE_NAME):$(HPC_IMAGE_TAG)"
	@$(DOCKER) image build \
		--build-arg BASE_IMAGE_NAME="$(BASE_IMAGE_NAME)" \
		--build-arg BASE_IMAGE_TAG="$(BASE_IMAGE_TAG)" \
		--build-arg DATA_IMAGE_NAME="$(DATA_IMAGE_NAME)" \
		--build-arg BINARY_DATA_TAG="$(BINARY_DATA_TAG)" \
		--build-arg SOURCE_DATA_TAG="$(SOURCE_DATA_TAG)" \
		--build-arg COMPILER="$(COMPILER)" \
		--build-arg MPI="$(MPI)" \
		--build-arg GPU="$(GPU)" \
		--file Containerfile.hpc \
		--label "org.opencontainers.image.revision=$$(git rev-parse --verify HEAD)" \
		--label "org.opencontainers.image.version=$(VERSION)" \
		--tag "$(HPC_IMAGE_NAME):$(HPC_IMAGE_TAG)" .

.PHONY: build-atm-sci
build-atm-sci:
	@echo "[$$(date -u "+%FT%TZ")] Building $(ATM_SCI_IMAGE_NAME):$(ATM_SCI_IMAGE_TAG)"
	@$(DOCKER) image build \
		--build-arg BASE_IMAGE_NAME="$(HPC_IMAGE_NAME)" \
		--build-arg BASE_IMAGE_TAG="$(HPC_IMAGE_TAG)" \
		--build-arg DATA_IMAGE_NAME="$(DATA_IMAGE_NAME)" \
		--build-arg SOURCE_DATA_TAG="$(SOURCE_DATA_TAG)" \
		--file Containerfile.atm-sci \
		--label "org.opencontainers.image.revision=$$(git rev-parse --verify HEAD)" \
		--label "org.opencontainers.image.version=$(VERSION)" \
		--tag "$(ATM_SCI_IMAGE_NAME):$(ATM_SCI_IMAGE_TAG)" .

.PHONY: push
push: push-hpc push-atm-sci

.PHONY: push-hpc
push-hpc:
	@echo "[$$(date -u "+%FT%TZ")] Pushing $(REGISTRY)/$(NAMESPACE)/$$(basename "$(HPC_IMAGE_NAME)"):$(HPC_IMAGE_TAG)"
	@$(DOCKER) image tag "$(HPC_IMAGE_NAME):$(HPC_IMAGE_TAG)" "$(REGISTRY)/$(NAMESPACE)/$$(basename "$(HPC_IMAGE_NAME)"):$(HPC_IMAGE_TAG)"
	@$(DOCKER) image push "$(REGISTRY)/$(NAMESPACE)/$$(basename "$(HPC_IMAGE_NAME)"):$(HPC_IMAGE_TAG)"

.PHONY: push-atm-sci
push-atm-sci:
	@echo "[$$(date -u "+%FT%TZ")] Pushing $(REGISTRY)/$(NAMESPACE)/$$(basename "$(ATM_SCI_IMAGE_NAME)"):$(ATM_SCI_IMAGE_TAG)"
	@$(DOCKER) image tag "$(ATM_SCI_IMAGE_NAME):$(ATM_SCI_IMAGE_TAG)" "$(REGISTRY)/$(NAMESPACE)/$$(basename "$(ATM_SCI_IMAGE_NAME)"):$(ATM_SCI_IMAGE_TAG)"
	@$(DOCKER) image push "$(REGISTRY)/$(NAMESPACE)/$$(basename "$(ATM_SCI_IMAGE_NAME)"):$(ATM_SCI_IMAGE_TAG)"

.PHONY: push-latest
push-latest: push-hpc-latest push-atm-sci-latest

.PHONY: push-hpc-latest
push-hpc-latest:
	@echo "[$$(date -u "+%FT%TZ")] Pushing $(REGISTRY)/$(NAMESPACE)/$$(basename "$(HPC_IMAGE_NAME)"):latest_$(COMPILER)_$(MPI)_$(GPU)"
	@$(DOCKER) image tag "$(HPC_IMAGE_NAME):$(HPC_IMAGE_TAG)" "$(REGISTRY)/$(NAMESPACE)/$$(basename "$(HPC_IMAGE_NAME)"):latest_$(COMPILER)_$(MPI)_$(GPU)"
	@$(DOCKER) image push "$(REGISTRY)/$(NAMESPACE)/$$(basename "$(HPC_IMAGE_NAME)"):latest_$(COMPILER)_$(MPI)_$(GPU)"

.PHONY: push-atm-sci-latest
push-atm-sci-latest:
	@echo "[$$(date -u "+%FT%TZ")] Pushing $(REGISTRY)/$(NAMESPACE)/$$(basename "$(ATM_SCI_IMAGE_NAME)"):latest_$(COMPILER)_$(MPI)_$(GPU)"
	@$(DOCKER) image tag "$(ATM_SCI_IMAGE_NAME):$(ATM_SCI_IMAGE_TAG)" "$(REGISTRY)/$(NAMESPACE)/$$(basename "$(ATM_SCI_IMAGE_NAME)"):latest_$(COMPILER)_$(MPI)_$(GPU)"
	@$(DOCKER) image push "$(REGISTRY)/$(NAMESPACE)/$$(basename "$(ATM_SCI_IMAGE_NAME)"):latest_$(COMPILER)_$(MPI)_$(GPU)"

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
	@$(DOCKER) image ls --quiet "$$(basename "$(HPC_IMAGE_NAME)")" | xargs -r $(DOCKER) image rm --force
	@$(DOCKER) image prune --force

.PHONY: clean-atm-sci
clean-atm-sci:
	@$(DOCKER) image ls --quiet "$$(basename "$(ATM_SCI_IMAGE_NAME)")" | xargs -r $(DOCKER) image rm --force
	@$(DOCKER) image prune --force

.PHONY: deep-clean
deep-clean: clean
	@$(DOCKER) container ls --all --quiet | xargs -r $(DOCKER) container stop
	@$(DOCKER) system prune --force --volumes

.PHONY: reset
reset:
	@$(DOCKER) system reset --force
