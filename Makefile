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

.PHONY: check
check: ## Checks formatting
	npm run check

.PHONY: test
test: ## Runs all test.scm files under test/ directories
	TEST_FILES=$$(find . -type f -path '*/test/*/test.scm' -not -path '*/.*')
	if [[ -z "$${TEST_FILES}" ]]; then
		echo "No test.scm files found under test/ directories"
		exit 0
	fi
	for test_file in $${TEST_FILES}; do
		echo "TEST: $${test_file}"
		guile -L ${PWD} -s "$${test_file}"
	done

.PHONY: test/regenerate
test/regenerate: ## Regenerates markdown .html fixtures from coordinated .md files
	TEST_FILES=$$(find . -type f -path '*/test/*/test.scm' -not -path '*/.*')
	if [[ -z "$${TEST_FILES}" ]]; then
		echo "No test.scm files found under test/ directories"
		exit 0
	fi
	for test_file in $${TEST_FILES}; do
		echo "REGENERATE: $${test_file}"
		guile -L ${PWD} -s "$${test_file}" --regenerate
	done

.PHONY: fix
fix: ## Fixes formatting issues
	npm run fix

.PHONY: format
format: ## Fixes formatting issues
	npm run fix:prettier

SCM_TEMPLATES := $(shell find templates/ -type f -not -path '*/.*' -name '*.html.scm')
_MD_TEMPLATES_ALL := $(shell find templates/ -type f -not -path '*/.*' -name '*.md')
MD_TEMPLATES := $(filter-out %body.md %README.md %AGENTS.md %CLAUDE.md,$(_MD_TEMPLATES_ALL))
SCM_RENDERS := $(patsubst templates/%.html.scm,wwwroot/%.html,$(SCM_TEMPLATES))
MD_RENDERS := $(patsubst templates/%.md,wwwroot/%.html,$(MD_TEMPLATES))
RENDERS := $(SCM_RENDERS) $(MD_RENDERS)

.PHONY: render
render: $(RENDERS) ## Renders the template files into their new home

wwwroot/%.html: templates/%.html.scm 
	echo "RENDER: $< -> $@"
	mkdir -p $$(dirname $@)
	: > $@
	guile \
		-L ${PWD} \
		-s $< >> $@

wwwroot/%.html: templates/%.md
	echo "RENDER: $< -> $@"
	mkdir -p $$(dirname $@)
	: > $@
	guile \
		-L ${PWD} \
		./scripts/render-md $< >> $@

.PHONY: serve
serve: ## Serve the application locally
	python3 -m http.server -d ./wwwroot --bind 127.0.0.1 8000

.PHONY: watch
watch: ## Watch for changes and re-render templates
	echo "Watching for changes in templates/..."
	while true; do
		inotifywait -e modify,create,delete -r templates/
		$(MAKE) -B render || true
	done

##@ Helpers

.PHONY: help
help: ## Displays help info
	awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
