#!/usr/bin/env sh
# Entry point for scripts/gsb-literal.scm: anchors the working directory to the
# repo root (the Scheme uses repo-relative paths) and hands off.
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
cd "${root}"
exec guile -L "${root}" -s "${root}/scripts/gsb-literal.scm" "$@"
