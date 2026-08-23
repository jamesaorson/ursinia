#!/usr/bin/env sh
# Entry point for scripts/generate-bible.scm.
#
# The Scheme reads and writes repo-relative paths, so anchor the working
# directory to the repo root before handing off. That lets this be run from
# anywhere, not just the top of the tree.
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
cd "${root}"
exec guile -L "${root}" -s "${root}/scripts/generate-bible.scm" "$@"
