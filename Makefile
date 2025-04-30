SHELL := /bin/bash
.SHELLFLAGS = -e -c
.DEFAULT_GOAL := render
.ONESHELL:

NO_GENERATE_TEMPLATES ?= 0

.PHONY: deploy
deploy: ./scripts/deploy ## Does an incremental deploy/redeploy of the application
	@if [[ "$(NO_GENERATE_TEMPLATES)" == "0" || -z "$(NO_GENERATE_TEMPLATES)" ]]; then
		$(MAKE) -B render
	fi
	$<

REMOTE_LOCATION ?= james@ursinia.net
REMOTE_DIR ?= ~/git.sr.ht/jamesaorson/ursinia.net

.PHONY: remote-deploy
remote-deploy: ./scripts/deploy ## Remotely deploys the application
	ssh -t $(REMOTE_LOCATION) "cd $(REMOTE_DIR) && git pull && make deploy"

TEMPLATES := $(shell find templates/ -type f -not -path '*/.*' -name '*.html.scm')
RENDERS := $(patsubst templates/%.html.scm,wwwroot/%.html,$(TEMPLATES))

.PHONY: render
render: $(RENDERS) ## Renders the template files into their new home
wwwroot/%.html: templates/%.html.scm 
	@echo "RENDER: $< -> $@"
	@mkdir -p $$(dirname $@)
	@: > $@
	@guile \
		-L ${PWD} \
		-s $< >> $@

.PHONY: get-certificate
get-certificate: ./scripts/get-certificate ## Install or refresh SSL certificates
	@$<

.PHONY: setup
setup: ./scripts/setup ## Setup dependencies for system
	@$<

UNAME_S := $(shell uname -s)

.PHONY: serve
serve: ## Serve the application locally
ifeq ($(UNAME_S),Linux)
	xdg-open http://localhost:8000
endif
ifeq ($(UNAME_S),Darwin)
	open http://localhost:8000
endif
	@python3 -m http.server -d ./wwwroot 8000

.PHONY: help
help: ## Displays help info
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
