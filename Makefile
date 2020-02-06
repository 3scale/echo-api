.PHONY: all build test run bash tag push pull help update build-builder build-dev stop-dev clean-dev \
	clean-dev-image clean-builder-image ensure-build ensure-builder ensure-dev

NAME = echoapi
NAMESPACE = quay.io/3scale
VERSION ?= new-echoapi
DOCKER ?= $(shell which podman 2> /dev/null || which docker 2> /dev/null || echo docker)
LOCAL_IMAGE := $(NAME):$(VERSION)
BUILDER_IMAGE := $(LOCAL_IMAGE)-builder
DEV_IMAGE := $(LOCAL_IMAGE)-dev
REMOTE_IMAGE := $(NAMESPACE)/$(LOCAL_IMAGE)
DEV_CONTAINER := $(NAME)-dev

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
THISDIR_PATH := $(patsubst %/,%,$(abspath $(dir $(MKFILE_PATH))))
PROJECT_PATH := $(patsubst %/,%,$(dir $(MKFILE_PATH)))


all: build

update: build test push

build: ## Build container image with name LOCAL_IMAGE (NAME:VERSION).
	$(DOCKER) build --target production -f $(THISDIR_PATH)/Dockerfile -t $(LOCAL_IMAGE) $(PROJECT_PATH)

build-builder:
	$(DOCKER) build --target builder -f $(THISDIR_PATH)/Dockerfile -t $(BUILDER_IMAGE) $(PROJECT_PATH)

ensure-build:
	@$(DOCKER) history -q $(LOCAL_IMAGE) 2> /dev/null >&2 || $(MAKE) -C $(PROJECT_PATH) -f $(MKFILE_PATH) build

ensure-builder:
	@$(DOCKER) history -q $(BUILDER_IMAGE) 2> /dev/null >&2 || $(MAKE) -C $(PROJECT_PATH) -f $(MKFILE_PATH) build-builder

ensure-dev:
	@$(DOCKER) history -q $(DEV_IMAGE) 2> /dev/null >&2 || $(MAKE) -C $(PROJECT_PATH) -f $(MKFILE_PATH) build-dev

build-dev: ensure-builder ## Build a development container image with name LOCAL_IMAGE (NAME:VERSION).
	@if echo "$(DOCKER)" | grep -q podman; then \
		DEV_UID=0; \
		DEV_GID=0; \
	else \
		DEV_UID=$$(id -u); \
		DEV_GID=$$(id -g); \
	fi && \
	$(DOCKER) build --target dev -f $(THISDIR_PATH)/Dockerfile -t $(DEV_IMAGE) --build-arg DEV_UID=$${DEV_UID} --build-arg DEV_GID=$${DEV_GID} $(PROJECT_PATH)
	@echo "Dev image ready."

stop-dev: ## Stop the development container
	$(DOCKER) stop $(DEV_CONTAINER)

clean-dev: ## Remove the development container
	-$(MAKE) -C $(PROJECT_PATH) -f $(MKFILE_PATH) stop-dev
	$(DOCKER) rm $(DEV_CONTAINER)

clean-dev-image: ## Remove the develpoment image
	-$(MAKE) -C $(PROJECT_PATH) -f $(MKFILE_PATH) clean-dev
	$(DOCKER) rmi $(DEV_IMAGE)

clean-builder-image: ## Remove the builder image
	-$(MAKE) -C $(PROJECT_PATH) -f $(MKFILE_PATH) clean-dev-image
	$(DOCKER) rmi $(BUILDER_IMAGE)

test: ensure-build ## Test built LOCAL_IMAGE (NAME:VERSION).
	$(DOCKER) run --rm --name $(VERSION) -d -p 9292:9292 $(LOCAL_IMAGE)
	@sleep 2
	curl -v "http://localhost:9292"
	@$(DOCKER) kill $(VERSION)
	@echo "Test OK."

run: ensure-build ## Run the container in the local machine.
	$(DOCKER) run --rm --name $(VERSION) -ti -p 9292:9292 $(LOCAL_IMAGE)

bash: ensure-build ## Start bash in the build IMAGE_NAME.
	$(DOCKER) run --rm -ti $(LOCAL_IMAGE) /bin/bash

dev: ensure-dev ## Start a development environment sync'ed with the code
	@if $(DOCKER) ps --filter name=$(DEV_CONTAINER) --format "{{.Names}}" | grep -q '^$(DEV_CONTAINER)$$' 2> /dev/null >&2; then \
		echo "Container $(DEV_CONTAINER) already started" >&2; false; \
	fi
	@if $(DOCKER) ps -a --filter name=$(DEV_CONTAINER) --format "{{.Names}}" | grep -q '^$(DEV_CONTAINER)$$' 2> /dev/null >&2; then \
		echo "Resuming existing $(DEV_CONTAINER) container." ; \
		$(DOCKER) start -ai $(DEV_CONTAINER) ; \
	else \
		if echo "$(DOCKER)" | grep -q podman; then \
			EXTRA_OPTS=""; \
		else \
			EXTRA_OPTS="-u $$(id -u):$$(id -g) --group-add 1001"; \
	        fi && \
		echo "Creating new $(DEV_CONTAINER) container." ; \
		$(DOCKER) run -ti -h $(DEV_CONTAINER) --expose=9292 -p 9292:9292 \
		-v $(THISDIR_PATH):$$($(DOCKER) run --rm $(DEV_IMAGE) /bin/bash -c 'pwd'):z \
		$${EXTRA_OPTS} \
		--name $(DEV_CONTAINER) $(DEV_IMAGE) /bin/bash ; \
	fi

tag: ensure-build ## Tag IMAGE_NAME in the container registry
	$(DOCKER) tag $(LOCAL_IMAGE) $(REMOTE_IMAGE)

push: tag ## Push to the container registry
	$(DOCKER) push $(REMOTE_IMAGE)

pull: ## Pull the container from the Registry
	$(DOCKER) pull $(REMOTE_IMAGE)

# Check http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Print this help
	@echo -e "Set the DOCKER variable to your docker-compatible program (Docker and Podman supported)\n"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
