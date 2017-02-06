.PHONY: all build test run bash tag push help

NAME=echoapi
NAMESPACE=quay.io/3scale
VERSION=centos7-to-ocp
LOCAL_IMAGE := $(NAME):$(VERSION)
REMOTE_IMAGE := $(NAMESPACE)/$(LOCAL_IMAGE)

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
THISDIR_PATH := $(patsubst %/,%,$(abspath $(dir $(MKFILE_PATH))))
PROJECT_PATH := $(patsubst %/,%,$(dir $(MKFILE_PATH)))


all: build

build: ## Build docker image with name LOCAL_IMAGE (NAME:VERSION).
	docker build -f $(THISDIR_PATH)/Dockerfile -t $(LOCAL_IMAGE) $(PROJECT_PATH)

test: ## Test built LOCAL_IMAGE (NAME:VERSION). 
	docker run -t --env RACK_ENV=$(ENVIRONMENT) $(LOCAL_IMAGE) rackup -D
	docker run -t $(LOCAL_IMAGE) 3scale_backend --version
	docker run -t --env RACK_ENV=$(ENVIRONMENT) $(LOCAL_IMAGE) 3scale_backend_worker --version
	docker run -t --env RACK_ENV=$(ENVIRONMENT) --env ONCE=1 $(LOCAL_IMAGE) backend-cron | grep "task crashed (RuntimeError)" > /dev/null # because redis is not running

run: ## Run the docker in the local machine.
	docker run -t -P $(LOCAL_IMAGE)

bash: ## Start bash in the build IMAGE_NAME.
	docker run --entrypoint=/bin/bash -it $(LOCAL_IMAGE)

tag: ## Tag IMAGE_NAME in the docker registry
	docker tag $(LOCAL_IMAGE) $(REMOTE_IMAGE)

push: ## Push to the docker registry
	docker push $(REMOTE_IMAGE)

# Check http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Print this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
