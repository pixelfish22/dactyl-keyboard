#SHELL := /bin/sh

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(dir $(mkfile_path))

source_dir := ${current_dir}"src"
artifact_dir := ${current_dir}"things"

DOCKER_CMD := "docker"
.DEFAULT_GOAL := help

help: ## Will print this help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
.PHONY: help

.DELETE_ON_ERROR:

build: build-container config build-models ## Build everything. Executes the complete pipeline.
	@echo "\nAll done"
.PHONY: build

check-requirements: # private
	@if ! command -v ${DOCKER_CMD} %> /dev/null; then \
		echo "Docker executable not found (\`${DOCKER_CMD}\`)." && \
		exit 1; \
	fi
.PHONY: check-requirements

build-container: check-requirements ## Build docker container.
	@echo "\nBuilding container..\n" && \
	${DOCKER_CMD} build -t dactyl-keyboard -f docker/Dockerfile . && \
	echo "Done"
.PHONY: build-container

config: check-requirements ## Generate configuration.
	@echo "\nGenerate configuration..\n" && \
	${DOCKER_CMD} run --rm --name DM-config -v ${source_dir}:/app/src -v ${artifact_dir}:/app/things dactyl-keyboard python3 -i generate_configuration.py && \
	echo "Done"
.PHONY: config

build-models: check-requirements ## Build models.
	@echo "\nGenerate configured model..\n" && \
	cd ${current_dir} && \
	${DOCKER_CMD} run --rm --name DM-run -v ${source_dir}:/app/src -v ${artifact_dir}:/app/things dactyl-keyboard python3 -i dactyl_manuform.py && \
	echo "Done"
.PHONY: config

build-models: check-requirements ## Build models.
	@echo "\nGenerate release models..\n" && \
	cd ${current_dir} && \
	${DOCKER_CMD} run --rm --name DM-release-build -v ${source_dir}:/app/src -v ${artifact_dir}:/app/things dactyl-keyboard python3 -i model_builder.py && \
	echo "Done"
.PHONY: config
docker run --name DM-release-build -d -v "%cd%/src:/app/src" -v "%cd%/things:/app/things" dactyl-keyboard python3 -i model_builder.py


shell: check-requirements ## Open an interactive shell inside a container.
	@${DOCKER_CMD} run --rm -it --name DM-shell -v "src:/app/src" -v "things:/app/things" dactyl-keyboard bash && \
	echo "\nBye!"
.PHONY: shell

