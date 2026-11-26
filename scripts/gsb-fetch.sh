#!/usr/bin/env sh
# Download the Greek Source Bible (GSB) source texts into gsb/sources/, each
# pinned to an upstream commit so a fetch is reproducible. The files are data:
# they are only ever parsed by scripts/gsb-build.scm, never executed.
#
# Every downloaded file is checked against gsb/sources/SHA256SUMS. To move a
# pin, edit the commit below, run with --update-sums, and review the diff.
set -eu

usage() {
	cat <<'EOF'
Usage: ./scripts/gsb-fetch.sh [OPTIONS]

Download the pinned GSB source texts into gsb/sources/ and verify their
checksums against gsb/sources/SHA256SUMS.

Options:
  -h, --help       Show this help
  --update-sums    Rewrite gsb/sources/SHA256SUMS from the downloaded files
                   (use after moving a pinned commit; review the diff)

Sources (all public domain or CC0; see each gsb/sources/*/README.md):
  nestle1904  biblicalhumanities/Nestle1904        (NT base text, CC0 morphology)
  tr          byztxt/greektext-textus-receptus     (Robinson's parsed TR)
  rp          byztxt/byzantine-majority-text       (Robinson-Pierpont, accents only)
  dodson      biblicalhumanities/Dodson-Greek-Lexicon (glosses)
  strongs     morphgnt/strongs-dictionary-xml      (Strong's dictionary)

The LXX text is our own transcription of Swete in gsb/sources/swete/; it is
not downloaded.

Examples:
  make gsb/fetch     Download everything
  make gsb           Then build gsb/greek/ from the downloads
EOF
}

update_sums=0
for arg in "$@"; do
	case "${arg}" in
	-h | --help) usage; exit 0 ;;
	--update-sums) update_sums=1 ;;
	*) echo "gsb-fetch: unknown argument '${arg}'" >&2; usage >&2; exit 2 ;;
	esac
done

for tool in curl shasum; do
	if ! command -v "${tool}" >/dev/null 2>&1; then
		echo "gsb-fetch: '${tool}' not found; install it (e.g. 'brew install ${tool}' or your package manager) and re-run" >&2
		exit 1
	fi
done

root=$(cd "$(dirname "$0")/.." && pwd)
cd "${root}/gsb/sources"

NESTLE=713f28a3b7d4d66132f5aa809fa223fe79762e5d
TR=33af6e9361f8db0afd353714d05c75f44e5555b9
RP=788ffe7c909e4d9c564ebed7083e93dd13d10b7c
DODSON=74f70358d4acfaf2f980bf2feb58ab7115cbbcbc
STRONGS=dd6758b82f46b620804a8ea677d715844679eea1

# get REPO COMMIT UPSTREAM-PATH LOCAL-PATH
get() {
	mkdir -p "$(dirname "$4")"
	echo "  $4"
	curl -fsSL --retry 3 -o "$4.part" "https://raw.githubusercontent.com/$1/$2/$3" || {
		rm -f "$4.part"
		echo "gsb-fetch: download failed: $1@$2 $3 -- check your network connection and re-run" >&2
		exit 1
	}
	mv -f "$4.part" "$4"
}

echo "Fetching Nestle 1904 (biblicalhumanities/Nestle1904@${NESTLE})"
get biblicalhumanities/Nestle1904 "${NESTLE}" morph/Nestle1904.csv nestle1904/Nestle1904.csv
get biblicalhumanities/Nestle1904 "${NESTLE}" morph/README.md nestle1904/morph-README.md
get biblicalhumanities/Nestle1904 "${NESTLE}" morph/parsing.txt nestle1904/parsing.txt

echo "Fetching Textus Receptus (byztxt/greektext-textus-receptus@${TR})"
for book in MT MR LU JOH AC RO 1CO 2CO GA EPH PHP COL 1TH 2TH 1TI 2TI TIT PHM HEB JAS 1PE 2PE 1JO 2JO 3JO JUDE RE; do
	get byztxt/greektext-textus-receptus "${TR}" "parsed/${book}.UTR" "tr/${book}.UTR"
done

echo "Fetching Robinson-Pierpont (byztxt/byzantine-majority-text@${RP})"
get byztxt/byzantine-majority-text "${RP}" LICENSE rp/LICENSE
for book in MAT MAR LUK JOH PA ACT ACT24 ROM 1CO 2CO GAL EPH PHP COL 1TH 2TH 1TI 2TI TIT PHM HEB JAM 1PE 2PE 1JO 2JO 3JO JUD REV; do
	get byztxt/byzantine-majority-text "${RP}" "csv-unicode/ccat/with-variants/${book}.csv" "rp/${book}.csv"
done

echo "Fetching Dodson lexicon (biblicalhumanities/Dodson-Greek-Lexicon@${DODSON})"
get biblicalhumanities/Dodson-Greek-Lexicon "${DODSON}" dodson.csv dodson/dodson.csv
get biblicalhumanities/Dodson-Greek-Lexicon "${DODSON}" LICENSE dodson/LICENSE

echo "Fetching Strong's dictionary (morphgnt/strongs-dictionary-xml@${STRONGS})"
get morphgnt/strongs-dictionary-xml "${STRONGS}" strongsgreek.xml strongs/strongsgreek.xml

if [ "${update_sums}" = 1 ]; then
	find nestle1904 tr rp dodson strongs -type f ! -name README.md | LC_ALL=C sort | xargs shasum -a 256 >SHA256SUMS
	echo "Wrote gsb/sources/SHA256SUMS -- review 'git diff gsb/sources/SHA256SUMS'"
elif [ -f SHA256SUMS ]; then
	shasum -a 256 -c --quiet SHA256SUMS || {
		echo "gsb-fetch: checksum mismatch against gsb/sources/SHA256SUMS; if you moved a pin on purpose run './scripts/gsb-fetch.sh --update-sums'" >&2
		exit 1
	}
	echo "Checksums OK"
else
	echo "gsb-fetch: gsb/sources/SHA256SUMS missing; run './scripts/gsb-fetch.sh --update-sums' to create it" >&2
	exit 1
fi
echo "Done. Next: make gsb"
