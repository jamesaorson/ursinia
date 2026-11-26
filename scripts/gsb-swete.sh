#!/usr/bin/env sh
# Entry point for scripts/gsb-swete.scm: anchors the working directory to the
# repo root and hands off. See ./scripts/gsb-swete.sh --help.
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
cd "${root}"
command -v guile >/dev/null 2>&1 || { echo "gsb-swete: guile not found: run ./scripts/gsb-swete-fetch.sh doctor" >&2; exit 1; }
exec guile -L "${root}" -s "${root}/scripts/gsb-swete.scm" "$@"
