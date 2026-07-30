IMAGE ?= clir-artifact:issta2026
OUTPUT_DIR ?= $(CURDIR)/output
IMAGE_ARCHIVE ?= clir-artifact-issta2026.tar.gz
BUILD_FLAGS ?=
DOCKER_RUN = docker run --rm --user "$$(id -u):$$(id -g)" \
	-v "$(OUTPUT_DIR):/output" $(IMAGE)

.PHONY: archive build help smoke-test reduced full shell

help:
	@echo "make build       Build the artifact image"
	@echo "make smoke-test  Generate and validate one target-specific case"
	@echo "make reduced     Run 10 cases in both modes"
	@echo "make full        Run 1,000 cases in both modes"
	@echo "make shell       Open an initialized artifact shell"
	@echo "make archive     Export the validated image as a gzip-compressed tar"

build:
	docker build $(BUILD_FLAGS) --tag "$(IMAGE)" .

archive:
	docker save "$(IMAGE)" | gzip -9 > "$(IMAGE_ARCHIVE)"

smoke-test:
	mkdir -p "$(OUTPUT_DIR)"
	$(DOCKER_RUN) smoke-test

reduced:
	mkdir -p "$(OUTPUT_DIR)"
	$(DOCKER_RUN) reduced

full:
	mkdir -p "$(OUTPUT_DIR)"
	$(DOCKER_RUN) full

shell:
	mkdir -p "$(OUTPUT_DIR)"
	docker run --rm -it --user "$$(id -u):$$(id -g)" \
		-v "$(OUTPUT_DIR):/output" "$(IMAGE)" shell
