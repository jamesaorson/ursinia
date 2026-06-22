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
		guile -L ${PWD} -L ${PWD}/scripts -s "$${test_file}"
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
		guile -L ${PWD} -L ${PWD}/scripts -s "$${test_file}" --regenerate
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
ASSET_FILES := $(shell find assets/ -type f -not -path '*/.*' 2>/dev/null)
SCM_RENDERS := $(patsubst templates/%.html.scm,wwwroot/%.html,$(SCM_TEMPLATES))
MD_RENDERS := $(patsubst templates/%.md,wwwroot/%.html,$(MD_TEMPLATES))
ASSET_RENDERS := $(patsubst assets/%,wwwroot/assets/%,$(ASSET_FILES))
RENDERS := $(SCM_RENDERS) $(MD_RENDERS) $(ASSET_RENDERS)

.PHONY: render
render: $(RENDERS) ## Renders the template files into their new home

.PHONY: clean
clean: ## Removes generated site output from wwwroot
	find wwwroot -type f -name '*.html' -delete
	rm -rf wwwroot/assets

wwwroot/%.html: templates/%.html.scm 
	echo "RENDER: $< -> $@"
	mkdir -p $$(dirname $@)
	: > $@
	guile \
		-L ${PWD} \
		-L ${PWD}/scripts \
		-s $< >> $@

wwwroot/%.html: templates/%.md
	echo "RENDER: $< -> $@"
	mkdir -p $$(dirname $@)
	: > $@
	guile \
		-L ${PWD} \
		-L ${PWD}/scripts \
		./scripts/render-md $< >> $@

wwwroot/assets/%: assets/%
	echo "ASSET: $< -> $@"
	mkdir -p $$(dirname $@)
	cp -f $< $@

.PHONY: serve
serve: ## Serve the application locally
	python3 -m http.server -d ./wwwroot --bind 127.0.0.1 8000

.PHONY: watch
watch: ## Watch for changes and re-render templates
	echo "Watching for changes in templates/ and assets/..."
	while true; do
		inotifywait -e modify,create,delete -r templates/ assets/
		$(MAKE) -B render || true
	done

##@ Helpers

.PHONY: help
help: ## Displays help info
	awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
