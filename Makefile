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
test: gsb/lint ## Runs all test.scm files under test/ directories, after gsb/lint
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

##@ Content Generation

.PHONY: bible
bible: ## Regenerates the amalgamated Bible markdown from the plain-text sources
	./scripts/generate-bible.sh

.PHONY: bible/check
bible/check: ## Verifies the committed Bible markdown matches its plain-text sources
	./scripts/generate-bible.sh --check

.PHONY: gsb/fetch
gsb/fetch: ## Downloads the pinned Greek Source Bible source texts into gsb/sources/
	./scripts/gsb-fetch.sh

.PHONY: gsb
gsb: ## Rebuilds the Greek Source Bible word tables (gsb/greek/) and reports from gsb/sources/
	./scripts/gsb-build.sh

.PHONY: gsb/check
gsb/check: ## Verifies the committed gsb/greek/ tables and reports match their sources
	./scripts/gsb-build.sh --check

.PHONY: gsb/swete/doctor gsb/swete/status gsb/swete/merge
gsb/swete/doctor: ## Checks the Swete transcription prerequisites
	./scripts/gsb-swete-fetch.sh doctor

gsb/swete/status: ## Shows done/missing/failing Swete leaves (BOOK=gen)
	./scripts/gsb-swete.sh status $(or $(BOOK),gen)

gsb/swete/merge: ## Rebuilds the Swete verse tables, decisions.tsv, provenance.tsv from per-leaf files
	./scripts/gsb-swete.sh merge

.PHONY: gsb/lint
gsb/lint: ## Checks the Greek Source Bible translation files (gsb/translation/) and concordance
	./scripts/gsb-check.sh

.PHONY: gsb/uses
gsb/uses: ## Lists every literal-layer use of a lemma with its sense and English (LEMMA=ἀρχή)
	@if [ -z "$(LEMMA)" ]; then echo "Usage: make gsb/uses LEMMA=<lemma as in gsb/greek/>, e.g. make gsb/uses LEMMA=ἀρχή" >&2; exit 2; fi
	./scripts/gsb-check.sh --uses "$(LEMMA)"

.PHONY: gsb/literal gsb/literal/check
gsb/literal: ## Regenerates the scripted hyper-literal English (gsb/literal/) from the Greek, form analyses, glosses and overrides
	./scripts/gsb-literal.sh generate

gsb/literal/check: ## Checks the data behind the scripted literal layer and lints its output
	./scripts/gsb-literal.sh check

GSB_DB := wwwroot/bible/versions/gsb/data/gsb.sqlite
GSB_DB_INPUTS := $(wildcard gsb/books.tsv gsb/README.md gsb/schema.sql gsb/greek/*.tsv gsb/lexicon/* \
	gsb/translation/*.md gsb/translation/*/*.scm gsb/reports/*.tsv gsb/sources/*/README.md \
	gsb/sources/swete/*.tsv gsb/sources/swete/pages/*/*.txt gsb/lexicon/glosses/*.scm \
	gsb/literal/*.scm gsb/literal/*/*.scm gsb/literal/*/*.tsv) \
	scripts/gsb-db.scm scripts/gsb-db.sh scripts/lib/gsb-db.scm scripts/lib/gsb.scm scripts/lib/gsb-translation.scm \
	scripts/lib/gsb-literal.scm scripts/lib/swete.scm scripts/lib/bible.scm

.PHONY: gsb/db
gsb/db: $(GSB_DB) ## Builds the Greek Source Bible database (and its .gz) from gsb/ into wwwroot/bible/versions/gsb/data/

$(GSB_DB): $(GSB_DB_INPUTS)
	./scripts/gsb-db.sh $@
	gzip -9 -n -c $@ > $@.gz

GSB_SITE_INPUTS := $(GSB_DB) scripts/gsb-site.scm scripts/gsb-site.sh scripts/lib/gsb-db.scm scripts/lib/gsb.scm \
	scripts/lib/md.scm scripts/lib/dirs.scm assets/bible/gsb/gsb.css assets/bible/gsb/gsb.js assets/bible/gsb/copy.css assets/bible/gsb/copy.js \
	$(wildcard templates/bible/versions/*/index.md)

.PHONY: gsb/site
gsb/site: wwwroot/bible/versions/gsb/index.html ## Renders every Greek Source Bible page from the database into wwwroot/bible/versions/gsb/

wwwroot/bible/versions/gsb/index.html: $(GSB_SITE_INPUTS)
	./scripts/gsb-site.sh
	touch $@

##@ Rendering

SCM_TEMPLATES := $(shell find templates/ -type f -not -path '*/.*' -name '*.html.scm')
_MD_TEMPLATES_ALL := $(shell find templates/ -type f -not -path '*/.*' -name '*.md')
# templates/bible/versions/gsb/index.md only names the page for the version list; gsb/site renders it.
MD_TEMPLATES := $(filter-out %body.md %README.md %AGENTS.md %CLAUDE.md templates/bible/versions/gsb/index.md,$(_MD_TEMPLATES_ALL))
ASSET_FILES := $(shell find assets/ -type f -not -path '*/.*' 2>/dev/null)
SCM_RENDERS := $(patsubst templates/%.html.scm,wwwroot/%.html,$(SCM_TEMPLATES))
MD_RENDERS := $(patsubst templates/%.md,wwwroot/%.html,$(MD_TEMPLATES))
ASSET_RENDERS := $(patsubst assets/%,wwwroot/assets/%,$(ASSET_FILES))
RENDERS := $(SCM_RENDERS) $(MD_RENDERS) $(ASSET_RENDERS)

.PHONY: render
render: $(RENDERS) gsb/site ## Renders the template files into their new home

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
		-s $< >> $@

wwwroot/%.html: templates/%.md
	echo "RENDER: $< -> $@"
	mkdir -p $$(dirname $@)
	: > $@
	guile \
		-L ${PWD} \
		./scripts/render-md.scm $< >> $@

wwwroot/assets/%: assets/%
	echo "ASSET: $< -> $@"
	mkdir -p $$(dirname $@)
	cp -f $< $@

.PHONY: serve
serve: ## Serve the application locally
	python3 -m http.server -d ./wwwroot --bind 127.0.0.1 8081

.PHONY: watch
watch: ## Watch for changes and re-render templates
	echo "Watching for changes in templates/ and assets/..."
	while true; do
		inotifywait -e modify,create,delete -r templates/ assets/
		$(MAKE) render || true
	done

##@ Helpers

.PHONY: help
help: ## Displays help info
	awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[a-zA-Z_\/-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
