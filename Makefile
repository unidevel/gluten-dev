ORG ?= unidevel
DESCRIPTION ?= "Gluten Dev Container"
DOCKER_CMD ?= $(shell if podman info > /dev/null 2>&1; then echo podman; else echo docker; fi)
DOCKERHUB ?= docker.io
CACHE_OPTION ?=
NUM_THREADS ?= 3
VERSION ?= $(shell grep -m 1 '^    <version>' ../pom.xml | sed -e 's/.*<version>\([^<]*\)<\/version>.*/\1/' -e 's/-SNAPSHOT//')
COMMIT_ID ?= $(shell git -C .. rev-parse --short HEAD)
TIMESTAMP ?= $(shell date '+%Y%m%d%H%M%S')
ARCH ?= $(shell uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/')
VELOX_SCRIPT_PATCH ?= scripts/velox-script.patch
ARM_BUILD_TARGET ?= apple

-include .env

.PHONY: centos-dep centos-cpp-dev centos-java-dev \
	centos-dev release-prepare release-publish pull-centos pull-ubuntu \
	latest-centos start-centos stop-centos \
	start stop info shell-centos shell prepare-home pull \
	centos-update-ccache down down-centos

default: start shell

centos-deps:
	env VERSION=$(VERSION) COMMIT_ID=$(COMMIT_ID) TIMESTAMP=$(TIMESTAMP) DESCRIPTION=$(DESCRIPTION) \
		$(DOCKER_CMD) compose build --build-arg CACHE_OPTION=$(CACHE_OPTION) --build-arg NUM_THREADS=$(NUM_THREADS) \
		centos-deps

centos-cpp:
	env VERSION=$(VERSION) COMMIT_ID=$(COMMIT_ID) TIMESTAMP=$(TIMESTAMP) DESCRIPTION=$(DESCRIPTION) \
		$(DOCKER_CMD) compose build --build-arg CACHE_OPTION=$(CACHE_OPTION) --build-arg NUM_THREADS=$(NUM_THREADS) \
		centos-cpp

centos-dev:
	env VERSION=$(VERSION) COMMIT_ID=$(COMMIT_ID) TIMESTAMP=$(TIMESTAMP) DESCRIPTION=$(DESCRIPTION) \
		$(DOCKER_CMD) compose build centos-dev

release-prepare:
	ORG=$(ORG) DOCKER_CMD=$(DOCKER_CMD) ARCH=$(ARCH) DOCKERHUB=$(DOCKERHUB) ./scripts/release.sh prepare

release-publish:
	ORG=$(ORG) DOCKER_CMD=$(DOCKER_CMD) ARCH=$(ARCH) DOCKERHUB=$(DOCKERHUB) ./scripts/release.sh publish

pull-centos:
	$(DOCKER_CMD) pull $(DOCKERHUB)/$(ORG)/gluten-dev:latest-$(ARCH)
	$(DOCKER_CMD) tag $(DOCKERHUB)/$(ORG)/gluten-dev:latest-$(ARCH) docker.io/apache/gluten:dev

prepare-home:
	@if [ ! -f "../.vscode/launch.json" ]; then \
		mkdir -p ../.vscode && cp ./launch.json ../.vscode/launch.json; \
	fi; \
	if [ ! -f root/.ssh/id_rsa ]; then \
		mkdir -p root/.ssh && cp $(HOME)/.ssh/authorized_keys root/.ssh/authorized_keys && \
		chmod 644 root/.ssh/authorized_keys; \
	fi; \
	test -e root/.m2 || test -L root/.m2 || ln -sfn /opt/cache/.m2 ./root/.m2; \
	test -e root/.ccache || test -L root/.ccache || ln -sfn /opt/cache/.ccache ./root/.ccache; \
	test -e root/.cache || test -L root/.cache || ln -sfn /opt/cache/.cache ./root/.cache;

start-centos: prepare-home
	@if [ -z "$$($(DOCKER_CMD) images -q apache/gluten:dev)" ]; then \
		echo "Image not found locally. Pulling..."; \
		make pull-centos; \
	fi
	VERSION=$(VERSION) COMMIT_ID=$(COMMIT_ID) TIMESTAMP=$(TIMESTAMP) DESCRIPTION=$(DESCRIPTION) \
		${DOCKER_CMD} compose -f docker-compose.yml -f docker-compose.rootful.yml up centos-dev -d
	${DOCKER_CMD} ps | grep gluten-dev

down-centos:
	VERSION=$(VERSION) COMMIT_ID=$(COMMIT_ID) TIMESTAMP=$(TIMESTAMP) DESCRIPTION=$(DESCRIPTION) \
		${DOCKER_CMD} compose down centos-dev

stop-centos:
	VERSION=$(VERSION) COMMIT_ID=$(COMMIT_ID) TIMESTAMP=$(TIMESTAMP) DESCRIPTION=$(DESCRIPTION) \
		${DOCKER_CMD} compose stop centos-dev

shell-centos: start-centos
	VERSION=$(VERSION) COMMIT_ID=$(COMMIT_ID) TIMESTAMP=$(TIMESTAMP) DESCRIPTION=$(DESCRIPTION) \
		${DOCKER_CMD} compose exec centos-dev bash -l

start: start-centos

stop: stop-centos

down: down-centos

shell: shell-centos

pull: pull-centos

info:
	@echo ${DOCKER_CMD} ${ORG} ${VERSION} ${COMMIT_ID}
