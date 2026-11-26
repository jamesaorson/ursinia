#!/usr/bin/env sh
# Fetch what the Swete transcription method reads for given scan leaves: the page
# image, archive.org's OCR layer (cut to one file per leaf) and a fresh Tesseract
# `grc` pass. Everything lands in a cache outside the repo; nothing here is
# committed. See .claude/skills/gsb-transcribe/SKILL.md for the method.
#
# Safe to run from several agents at once: every download goes to a private
# temporary name and is renamed into place.
set -eu

prog=gsb-swete-fetch
cache=${GSB_SWETE_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/gsb-swete}
tessdata=$cache/tessdata
# Tesseract's Ancient Greek LSTM model (tessdata_best), pinned.
grc_url=https://github.com/tesseract-ocr/tessdata_best/raw/main/grc.traineddata
grc_sha256=dfc9bda286cd9d8755b1832e5731a5425d1cf0803393a5fa6dee078466178cf1

usage() {
  cat <<EOF
Usage: ./scripts/$prog.sh VOLUME LEAF...
       ./scripts/$prog.sh doctor

Download page images (and OCR layers) of Swete's "The Old Testament in Greek"
from archive.org into $cache/<identifier>/:
  leaf-NNNN.jpg        full-resolution page image (scan leaf NNNN)
  leaf-NNNN.ia.hocr    archive.org's OCR layer for that leaf (reading A)
  leaf-NNNN.tess.hocr  fresh Tesseract pass with the grc model (reading B)
  <identifier>_hocr.html  archive.org's OCR layer for the whole volume (~85 MB, once)
The Tesseract grc model is downloaded once into $tessdata.

VOLUME is 1 (Genesis-4 Kingdoms), 2 (1 Chronicles-Tobit) or 3 (Hosea-4 Maccabees).
LEAF is the scan leaf number (archive.org leafNum, 1-based), not the printed page;
printed page p of vol. I is leaf p+32, of vol. III leaf p+24.
gsb/sources/swete/leaves.tsv lists each book's leaves.

Set GSB_SWETE_CACHE to put the cache elsewhere.

Examples:
  ./scripts/$prog.sh doctor          Check every prerequisite and print fixes
  ./scripts/$prog.sh 1 39 40 41      Genesis printed pages 7-9
  ./scripts/$prog.sh 3 522 523       Daniel 1 (Old Greek p. 498, Theodotion p. 499)
EOF
}

die() { echo "$prog: $*" >&2; exit 1; }

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1"; else shasum -a 256 "$1"; fi | cut -d' ' -f1
}

has_grc() { [ -s "$tessdata/grc.traineddata" ] && [ "$(sha256 "$tessdata/grc.traineddata")" = "$grc_sha256" ]; }

doctor() {
  bad=0
  check() { # NAME FIX...
    n=$1; shift
    if command -v "$n" >/dev/null 2>&1; then echo "ok    $n"
    else echo "FAIL  $n not found. Fix: $*"; bad=1; fi
  }
  check curl "brew install curl (or your package manager)"
  check ffmpeg "brew install ffmpeg"
  check tesseract "brew install tesseract (5.x; no language packs needed)"
  check guile "brew install guile (3.x)"
  if command -v tesseract >/dev/null 2>&1; then
    tesseract --version 2>/dev/null | head -1 | grep -q 'tesseract 5' \
      || { echo "WARN  $(tesseract --version 2>/dev/null | head -1): the method was measured with tesseract 5.x"; }
  fi
  if has_grc; then echo "ok    grc model ($tessdata/grc.traineddata)"
  else echo "FAIL  grc model missing or not the pinned one. Fix: ./scripts/$prog.sh 1 33   (downloads it)"; bad=1; fi
  mkdir -p "$cache" 2>/dev/null && [ -w "$cache" ] && echo "ok    cache $cache" \
    || { echo "FAIL  cache $cache is not writable. Fix: set GSB_SWETE_CACHE to a writable directory"; bad=1; }
  [ $bad = 0 ] && echo "All prerequisites present." || echo "Fix the FAIL lines above, then rerun: ./scripts/$prog.sh doctor"
  exit $bad
}

# download URL DEST: fetch to a private temp file, rename into place.
download() {
  tmp=$2.part.$$
  curl -fsSL --retry 3 -o "$tmp" "$1" || { rm -f "$tmp"; return 1; }
  mv -f "$tmp" "$2"
}

case "${1:-}" in
  '') usage >&2; exit 2 ;;
  -h|--help) usage; exit 0 ;;
  doctor) doctor ;;
  1) id=theoldtestamenti00unknuoft ;;
  2) id=oldtestamenting02swet ;;
  3) id=oldtestgreek00unknuoft ;;
  *) die "unknown volume '$1': use 1, 2 or 3 (see --help)" ;;
esac
shift
[ $# -gt 0 ] || die "no leaves given: e.g. ./scripts/$prog.sh 1 39 40 (see --help)"
for leaf in "$@"; do
  case "$leaf" in *[!0-9]*|'') die "leaf '$leaf' is not a number (see --help)" ;; esac
done
for t in curl ffmpeg tesseract; do
  command -v $t >/dev/null 2>&1 || die "$t not found: run ./scripts/$prog.sh doctor for the fix"
done

mkdir -p "$tessdata"
if ! has_grc; then
  echo "$prog: downloading the Tesseract grc model" >&2
  download "$grc_url" "$tessdata/grc.traineddata" || die "grc model download failed: check the network, then rerun"
  has_grc || die "grc model checksum mismatch: delete $tessdata/grc.traineddata and rerun"
fi

dir=$cache/$id
mkdir -p "$dir"

# Volume files. archive.org/download/ may redirect to a mirror that stalls on the
# 85 MB hOCR, so ask the metadata API for the item's primary server instead.
for f in page_numbers.json hocr.html; do
  [ -s "$dir/${id}_$f" ] && continue
  if [ -z "${base:-}" ]; then
    base=https://archive.org/download/$id
    meta=$(curl -fsSL --retry 3 "https://archive.org/metadata/$id" 2>/dev/null || true)
    d1=$(printf '%s' "$meta" | sed -n 's/.*"d1":"\([^"]*\)".*/\1/p')
    idir=$(printf '%s' "$meta" | sed -n 's/.*"dir":"\([^"]*\)".*/\1/p')
    [ -n "$d1" ] && [ -n "$idir" ] && base=https://$d1$idir
  fi
  echo "$prog: downloading ${id}_$f" >&2
  download "$base/${id}_$f" "$dir/${id}_$f" || die "download of ${id}_$f failed: check the network, then rerun"
done

for leaf in "$@"; do
  n=$(printf %04d "$leaf")
  img=$dir/leaf-$n.jpg
  if [ ! -s "$img" ]; then
    # /page/nK is 0-based: leaf L is n(L-1).
    download "https://archive.org/download/$id/page/n$((leaf - 1)).jpg" "$img" \
      || die "download of leaf $leaf failed: check the leaf against gsb/sources/swete/leaves.tsv"
  fi
  if [ ! -s "$dir/leaf-$n.ia.hocr" ]; then
    # Leaf L is the volume hOCR's ocr_page whose image is ..._LLLL.jp2.
    awk -v key="_$n.jp2" '/class="ocr_page"/ { p = index($0, key) > 0 } p' \
      "$dir/${id}_hocr.html" > "$dir/leaf-$n.ia.hocr.$$"
    [ -s "$dir/leaf-$n.ia.hocr.$$" ] || echo "$prog: archive OCR has no page for leaf $leaf" >&2
    mv -f "$dir/leaf-$n.ia.hocr.$$" "$dir/leaf-$n.ia.hocr"
  fi
  if [ ! -s "$dir/leaf-$n.tess.hocr" ]; then
    TESSDATA_PREFIX=$tessdata tesseract "$img" "$dir/leaf-$n.tess.$$" -l grc --psm 3 \
        -c tessedit_create_hocr=1 -c tessedit_create_txt=0 >/dev/null 2>&1 \
      && mv -f "$dir/leaf-$n.tess.$$.hocr" "$dir/leaf-$n.tess.hocr" \
      || echo "$prog: tesseract failed on leaf $leaf; run ./scripts/$prog.sh doctor" >&2
  fi
  echo "$img"
done
