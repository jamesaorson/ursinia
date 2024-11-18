SHELL := /bin/bash
.SHELLFLAGS = -e -c
.DEFAULT_GOAL := help
.ONESHELL:

NO_GENERATE_TEMPLATES ?= 0

.PHONY: deploy
deploy: ./scripts/deploy ## Does an incremental deploy/redeploy of the application
	@if [[ "$(NO_GENERATE_TEMPLATES)" == "0" || -z "$(NO_GENERATE_TEMPLATES)" ]]; then
		$(MAKE) render
	fi
	$<

TEMPLATES := $(shell find templates/ -type f -name '*.scm')
RENDERS := $(patsubst templates/%.scm,src/%.html,$(TEMPLATES))

$(RENDERS): $(TEMPLATES)
render: $(RENDERS)
src/%.html: templates/%.scm
	@echo "RENDER: $< -> $@"
	: > $@
	guile \
		-L ${PWD} \
		-s $< >> $@

.PHONY: get-certificate
get-certificate: ./scripts/get-certificate ## Install or refresh SSL certificates
	@$<

.PHONY: setup
setup: ./scripts/setup ## Setup dependencies for system
	@$<

.PHONY: help
help: ## Displays help info
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
