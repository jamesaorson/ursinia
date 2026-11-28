;; Fixed Greek phrases the generator renders as one English segment
;; (gsb/literal/README.md). Matched on consecutive lemmas; SENSES names the
;; concordance sense of each word; TAG (optional) is the grammar of the whole,
;; else the last word's.

(phrase (lemmas "ἀνά" "μέσος") (senses meson between) (english "between") (tag "PREP")
  (why "ἀνὰ μέσον is the Septuagint's \"between\"; the concordance gives the English to μέσος (sense between) and leaves ἀνά unrendered."))

(phrase (lemmas "ἐν" "μέσος") (senses in midst) (english "in [the] midst")
  (why "ἐν μέσῳ, \"in [the] midst\"; the following genitive takes \"of\" (\"in [the] midst of the water\", Genesis 1:6)."))

(phrase (lemmas "ἵνα" "τίς") (senses why-phrase why) (english "why") (tag "ADV")
  (why "ἵνα τί, \"why\" (\"for what\")."))

(phrase (lemmas "ἀλλά" "ἤ") (senses rather alla-phrase) (english "rather") (tag "CONJ")
  (why "ἀλλ’ ἤ, \"but rather, except\" after a negative (Genesis 19:2 Οὐχί, ἀλλ’ ἢ ἐν τῇ πλατείᾳ καταλύσομεν; 28:17; 2 Corinthians 1:13): word for word \"rather or\", which does not read."))

(phrase (lemmas "εἰ" "μήν (I)") (senses oath surely) (english "surely") (tag "ADV")
  (why "εἰ μήν, the Septuagint's oath formula \"surely\" (Genesis 22:17, quoted in Hebrews 6:14; Numbers 14:28): word for word \"if surely\", which reads as a condition."))

(phrase (lemmas "κύριος" "ὁ" "θεός" "σύ") (senses lord the god pronoun) (english "the Lord your God")
  (why "Κύριος ὁ θεός σου (ὑμῶν): the possessive goes before \"God\", inside the name phrase (Exodus 20:2)."))

(phrase (lemmas "κύριος" "ὁ" "θεός") (senses lord the god) (english "the Lord God")
  (why "Κύριος ὁ θεός (any case): the article before θεός carries the English \"the\", moved to the front (hand drafts, Genesis 2 chapter note)."))
