CONTEXT="."

BOLD :=$(shell tput bold)
RED :=$(shell tput setaf 1)
GREEN :=$(shell tput setaf 2)
YELLOW :=$(shell tput setaf 3)
RESET :=$(shell tput sgr0)

NAME := $(shell basename $(PWD))
LIST_TAGS := $(shell git tag -l)
IMAGE_NAME=rajasoun/$(NAME)
VERSION := $(shell [ "${LIST_TAGS}" ] && echo "$(shell git describe --tags --abbrev=0 >/dev/null 2>&1)" ||  echo "1.0.0"  )

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

# DOCKER TASKS
# Build the container

prerequisite: ## Pre-Requisite Checks
	@echo "$(GREEN)\nTools PreRequisite Checks $(RESET)"
	@code --version >/dev/null 2>&1 && (echo "✅ Visual Studio Code") || (echo  "❌ Visual Studio Code")
	@make --version >/dev/null 2>&1 && (echo "✅ make") || (echo  "❌ make")
	@echo ""
	@echo "$(GREEN)\nConfigs PreRequisite Checks $(RESET)"
	@ls -asl .devcontainer/dotfiles/.gitconfig >/dev/null 2>&1 && (echo "✅ .gitconfig File") || (echo  "❌ .gitconfig File. Execute -> .devcontainer/dotfiles/generate_git_config.sh")
	@ls -asl .devcontainer/.gpg2/private.key >/dev/null 2>&1 && (echo "✅ gpg2 config") || (echo  "❌ gpg2 config. Execute -> .devcontainer/.gpg2/generate-gpg-key.sh")
	@ls -asl .devcontainer/.store/.gpg-id >/dev/null 2>&1 && (echo "✅ password-store config") || (echo  "❌ password-store config. Execute -> .devcontainer/.store/initialize_store.sh")
	@ls -asl .devcontainer/.aws/config >/dev/null 2>&1 && (echo "✅ aws config") || (echo  "❌ aws config. Execute -> ???")
	@ls -asl .ssh >/dev/null 2>&1 && (echo "✅ .ssh Folder") || (echo  "❌ .ssh Folder")
	@echo ""

login: ## Login To Docker
	@echo "$(BOLD)$(YELLOW) Login to Docker Registry $(RESET)"
	cat .dockerhub.token | docker login --username rajasoun --password-stdin
	@echo "$(BOLD)$(GREEN)Completed Login to Docker Registry $(RESET)"

version:
	@echo "Current Version : "$(VERSION)
	$(eval VERSION=$(shell echo $(VERSION) | awk -F. '{OFS="."; $$NF+=1; print $0}'))
	@echo "Version to be Bumped: "$(VERSION)

# Pre-Requisites:
#	1. One Time - Create Manual Release :ToDo - To be Automated
#	2. Edit devcontainer.json - UnComment line 7 & Comment line 9 & 10
build:  ## Build the container - Copy of Visual Studio Code Container
	@echo "$(BOLD)$(YELLOW)Building docker image - $(IMAGE_NAME):$(VERSION) $(RESET)"
	devcontainer build --image-name $(IMAGE_NAME):$(VERSION)
	@echo "$(BOLD)$(GREEN)Completed building docker image - $(IMAGE_NAME):$(VERSION) $(RESET)"

push: login ## Push to Docker Hub
	@echo "$(BOLD)$(YELLOW) Push to Docker Registry $(RESET)"
	docker push $(IMAGE_NAME):$(VERSION)
	@echo "$(BOLD)$(GREEN)Completed Push to Docker Registry for $(IMAGE_NAME):$(VERSION) $(RESET)"

git:  ## Rebase latest version details, tag release and do checkin
	@echo "$(BOLD)$(YELLOW)Git updates - $(IMAGE_NAME):$(VERSION) $(RESET)"
	$(eval VERSION=$(shell echo $(VERSION) | awk -F. '{OFS="."; $$NF+=1; print $0}'))
	@echo "$(VERSION)" >.devcontainer/version.txt
	@echo "FROM $(IMAGE_NAME):$(VERSION)" >.devcontainer/prebuild/Dockerfile.prebuilt
	git add .devcontainer/version.txt .devcontainer/prebuild/Dockerfile.prebuilt
	HUSKY=0 git commit -m "ci(devcontainer): new version - $(VERSION)" --no-verify
	git push --no-verify
	git fetch --prune --tags
	git tag -a "$(VERSION)" -m "Dev Container new Build $(VERSION)"
	git push origin "$(VERSION)" --no-verify
	@echo "$(BOLD)$(GREEN)Completed Git updates - $(IMAGE_NAME):$(VERSION) $(RESET)"

clean: ## Remove Base Container Image
	@echo "$(BOLD)$(YELLOW)Removing docker image locally - $(IMAGE_NAME) $(RESET)"
	$(eval IMAGES=$(shell docker images $(IMAGE_NAME) -a -q ))
	docker rmi --force $(IMAGES)
	@echo "$(BOLD)$(GREEN)Completed removing docker image - $(IMAGE_NAME) $(RESET)"

all:  prerequisite git build login push clean ## All in One Command - (prerequisite git build login push clean)
