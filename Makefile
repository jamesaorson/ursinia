SHELL := /usr/bin/env
.SHELLFLAGS = bash -e -c
.DEFAULT_GOAL := help
.ONESHELL:
.SILENT:

UNAME_S := $(shell uname -s)

NO_GENERATE_TEMPLATES ?= 0

##@ Development Environment

.PHONY: setup
setup: ./scripts/setup ## Setup dependencies for system
	$<

##@ Local Development

.PHONY: deploy
deploy: ./scripts/deploy ## Does an incremental deploy/redeploy of the application
	if [[ "$(NO_GENERATE_TEMPLATES)" == "0" || -z "$(NO_GENERATE_TEMPLATES)" ]]; then
		$(MAKE) -B render
	fi
	$<

.PHONY: render
render: $(RENDERS) ## Renders the template files into their new home
wwwroot/%.html: templates/%.html.scm 
	echo "RENDER: $< -> $@"
	mkdir -p $$(dirname $@)
	: > $@
	guile \
		-L ${PWD} \
		-s $< >> $@

.PHONY: serve
serve: ## Serve the application locally
ifeq ($(UNAME_S),Linux)
	xdg-open http://localhost:8000
endif
ifeq ($(UNAME_S),Darwin)
	open http://localhost:8000
endif
	@python3 -m http.server -d ./wwwroot 8000

.PHONY: watch
watch: ## Watch for changes and re-render templates
	echo "Watching for changes in templates/..."
	while true; do
		inotifywait -e modify,create,delete -r templates/
		$(MAKE) -B render
	done

##@ Helpers

.PHONY: help
help: ## Displays help info
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
