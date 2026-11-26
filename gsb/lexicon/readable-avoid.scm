;; Greek Source Bible: words the readable layer does not use.
;;
;; The readable layer uses words people understand today (gsb/AGENTS.md, rule
;; 9). Each entry is a word or phrase that is no longer naturally understood,
;; or now misleads, with what to write instead and why. `make gsb/lint` fails
;; when a readable layer contains one (whole words, case-insensitive). The
;; literal layer may keep the stricter concordance gloss. Add an entry
;; whenever the owner rejects a word for the readable layer.
;;
;;   (avoid "<word or phrase>" (use "<replacement>") (why "<reason>"))

(avoid "borne"
  (use "moving")
  (why "\"was being borne over the water\" is not natural modern English; Genesis 1:2 reads \"was moving over the water\" (owner, 2026-11-26)"))
