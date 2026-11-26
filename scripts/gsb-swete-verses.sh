#!/usr/bin/env sh
# Entry point for scripts/gsb-swete-verses.scm: anchors the working directory to
# the repo root and hands off.
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
cd "${root}"
exec guile -L "${root}" -s "${root}/scripts/gsb-swete-verses.scm" "$@"
