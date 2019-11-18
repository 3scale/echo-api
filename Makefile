.PHONY: all build test run bash tag push pull help

NAME = echoapi
NAMESPACE = quay.io/3scale
VERSION ?= new-echoapi
DOCKER ?= $(shell which podman 2> /dev/null || echo docker)
LOCAL_IMAGE := $(NAME):$(VERSION)
REMOTE_IMAGE := $(NAMESPACE)/$(LOCAL_IMAGE)

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
THISDIR_PATH := $(patsubst %/,%,$(abspath $(dir $(MKFILE_PATH))))
PROJECT_PATH := $(patsubst %/,%,$(dir $(MKFILE_PATH)))


all: build

update: build test push

build: ## Build docker image with name LOCAL_IMAGE (NAME:VERSION).
	$(DOCKER) build -f $(THISDIR_PATH)/Dockerfile -t $(LOCAL_IMAGE) $(PROJECT_PATH)

test: ## Test built LOCAL_IMAGE (NAME:VERSION).
	$(DOCKER) run --rm -u 10000001 --name $(VERSION) -t -p 9292:9292 -d $(LOCAL_IMAGE)
	@sleep 1
	curl localhost:9292
	$(DOCKER) kill $(VERSION)

run: ## Run the docker in the local machine.
	$(DOCKER) run --rm -u 10000001 -t -P $(LOCAL_IMAGE)

bash: ## Start bash in the build IMAGE_NAME.
	$(DOCKER) run --rm --entrypoint=/bin/bash -it $(LOCAL_IMAGE)


tag: ## Tag IMAGE_NAME in the docker registry
	$(DOCKER) tag $(LOCAL_IMAGE) $(REMOTE_IMAGE)

push: tag ## Push to the docker registry
	$(DOCKER) push $(REMOTE_IMAGE)

pull: ## Pull the docker from the Registry
	$(DOCKER) pull $(REMOTE_IMAGE)

# Check http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Print this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
