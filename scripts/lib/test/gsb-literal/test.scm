;; Copyright (C) 2026
;;
;; Checks for (scripts lib gsb-literal): grammar tags, English inflection, and
;; the rendering rules on small verses with a hand-made lexicon. Run by
;; `make test`.

(use-modules (scripts lib gsb-literal)
             (scripts lib gsb-translation)
             (srfi srfi-1)
             (ice-9 format))

(define failures 0)
(define (check what got want)
  (unless (equal? got want)
    (set! failures (+ failures 1))
    (format #t "FAIL ~a:~%  got  ~s~%  want ~s~%" what got want)))

;; Tags.
(check "verb tag" (tag-field (parse-tag "V-2AAI-3S") 'tense) #\A)
(check "verb person with suffix" (tag-field (parse-tag "V-RAI-2P-ATT") 'person) #\2)
(check "pronoun person" (tag-field (parse-tag "P-1GS") 'person) #\1)
(check "possessive adjective case" (tag-field (parse-tag "S-1PASF") 'case) #\A)
(check "indeclinable name" (tag-field (parse-tag "N-PRI") 'case) #f)

;; English morphology.
(check "past" (map english-past '("make" "carry" "sin" "open")) '("made" "carried" "sinned" "opened"))
(check "ing" (map english-ing '("make" "die" "see")) '("making" "dying" "seeing"))
;; consonant doubling by rule (one syllable consonant-vowel-consonant) and list
(check "ing doubling" (map english-ing '("blot" "run" "beget" "open" "visit" "snow" "fix" "rain"))
       '("blotting" "running" "begetting" "opening" "visiting" "snowing" "fixing" "raining"))
(check "past doubling" (map english-past '("blot" "beg" "prosper")) '("blotted" "begged" "prospered"))
(check "plural" (map english-plural '("fig tree" "man" "city")) '("fig trees" "men" "cities"))

;; A tiny lexicon and two verses (Genesis 1:3 and 2:7-like).
(define senses
  (gloss-senses
   '((lemma "καί" (sense and (gloss "and") (why "w")))
     (lemma "λέγω" (sense say (gloss "say" "said") (why "w")))
     (lemma "ὁ" (sense the (gloss "the") (why "w")) (sense unrendered (gloss "") (why "w"))
       (sense attributive (gloss "") (why "w")) (sense infinitive (gloss "") (why "w")) (sense absorbed (gloss "") (why "w")))
     (lemma "θεός" (sense god (gloss "God") (why "w")))
     (lemma "γίνομαι" (sense come-to-be (subject "it") (gloss "come to be" "came to be") (why "w")))
     (lemma "φῶς" (sense light (gloss "light") (why "w")))
     (lemma "ἐμφυσάω" (sense breathe (gloss "breathe" "breathed") (why "w")))
     (lemma "εἰς" (sense into (gloss "into") (why "w")))
     (lemma "πρόσωπον" (sense face (gloss "face") (why "w")))
     (lemma "αὐτός" (sense pronoun (gloss "he" "him" "his" "it" "its") (why "w")))
     (lemma "ἄνθρωπος" (sense human (person) (gloss "human") (why "w")))
     (lemma "μετά" (sense with (gloss "with") (why "w")) (sense after (object-case "A") (gloss "after") (why "w")))
     (lemma "γεννάω" (sense beget (gloss "beget" "begetting") (why "w")))
     (lemma "Σήθ" (sense name (gloss "Seth") (why "w")))
     (lemma "ἡμέρα" (sense day (gloss "day") (why "w")))
     (lemma "ἁγιάζω" (sense sanctify (gloss "sanctify") (why "w"))))))

(define (row n word post lemma tag) (list n "" word post lemma "" "" '()))
(define forms
  (index-forms-rows
   '(("καὶ" "καί" "CONJ") ("εἶπεν" "λέγω" "V-2AAI-3S") ("ὁ" "ὁ" "T-NSM") ("θεός" "θεός" "N-NSM")
     ("Γενηθήτω" "γίνομαι" "V-AOM-3S") ("φῶς" "φῶς" "N-NSN") ("ἐγένετο" "γίνομαι" "V-2ADI-3S")
     ("ἐνεφύσησεν" "ἐμφυσάω" "V-AAI-3S") ("εἰς" "εἰς" "PREP") ("τὸ" "ὁ" "T-ASN") ("πρόσωπον" "πρόσωπον" "N-ASN")
     ("αὐτοῦ" "αὐτός" "P-GSM") ("τὸν" "ὁ" "T-ASM") ("ἄνθρωπον" "ἄνθρωπος" "N-ASM")
     ("μετὰ" "μετά" "PREP") ("γεννῆσαι" "γεννάω" "V-AAN") ("αὐτὸν" "αὐτός" "P-ASM") ("Σήθ" "Σήθ" "N-PRI")
     ("τὴν" "ὁ" "T-ASF") ("ἡμέραν" "ἡμέρα" "N-ASF") ("ἁγιάζειν" "ἁγιάζω" "V-PAN") ("αὐτήν" "αὐτός" "P-ASF"))))
(define env (make-env forms (make-hash-table) senses '() (make-hash-table) (make-hash-table)))

(define (english ref words)
  (call-with-values (lambda () (render-verse env ref words #t))
    (lambda (segs stop?) (string-join (map car segs) " "))))

;; Subject before the verb; "Let ... come to be" around the subject; speech comma.
(check "Genesis 1:3"
       (english "gen.1.3" (list (row 1 "καὶ" "" "καί" "") (row 2 "εἶπεν" "" "λέγω" "") (row 3 "ὁ" "" "ὁ" "")
                                (row 4 "θεός" "" "θεός" "") (row 5 "Γενηθήτω" "" "γίνομαι" "") (row 6 "φῶς" "·" "φῶς" "")
                                (row 7 "καὶ" "" "καί" "") (row 8 "ἐγένετο" "" "γίνομαι" "") (row 9 "φῶς" "." "φῶς" "")))
       "And God said, Let light come to be; and light came to be.")

;; Rule 16a: an unstated third singular subject stays "he/she/it"; a verb
;; joined by καί to the verb before (same person and number) has none;
;; αὐτοῦ (masculine or neuter)
;; is "his" when its nearest agreeing noun is a person, "its" for a thing,
;; "his/its" when there is none.
(check "open subject, καί-joined verb"
       (english "gen.2.7" (list (row 1 "καὶ" "" "καί" "") (row 2 "εἶπεν" "" "λέγω" "") (row 3 "τὸν" "" "ὁ" "")
                                (row 4 "ἄνθρωπον" "" "ἄνθρωπος" "") (row 5 "καὶ" "" "καί" "") (row 6 "ἐνεφύσησεν" "" "ἐμφυσάω" "")
                                (row 7 "εἰς" "" "εἰς" "") (row 8 "τὸ" "" "ὁ" "") (row 9 "πρόσωπον" "" "πρόσωπον" "")
                                (row 10 "αὐτοῦ" "." "αὐτός" "")))
       "And he/she/it said the human and breathed into his face.")
(check "possessive with a person as nearest agreeing noun"
       (english "gen.2.7" (list (row 1 "εἶπεν" "" "λέγω" "") (row 2 "τὸν" "" "ὁ" "") (row 3 "ἄνθρωπον" "" "ἄνθρωπος" "")
                                (row 4 "εἰς" "" "εἰς" "") (row 5 "τὸ" "" "ὁ" "") (row 6 "πρόσωπον" "" "πρόσωπον" "")
                                (row 7 "αὐτοῦ" "." "αὐτός" "")))
       "He/she/it said the human into his face.")
(check "masculine/neuter pronoun left open"
       (english "gen.2.7" (list (row 1 "ἐνεφύσησεν" "" "ἐμφυσάω" "") (row 2 "εἰς" "" "εἰς" "") (row 3 "τὸ" "" "ὁ" "")
                                (row 4 "πρόσωπον" "" "πρόσωπον" "") (row 5 "αὐτοῦ" "." "αὐτός" "")))
       "He/she/it breathed into his/its face.")

;; Preposition + article + infinitive + accusative subject: a possessive gerund.
(check "articular infinitive with its subject"
       (english "gen.5.4" (list (row 1 "μετὰ" "" "μετά" "") (row 2 "τὸ" "" "ὁ" "") (row 3 "γεννῆσαι" "" "γεννάω" "")
                                (row 4 "αὐτὸν" "" "αὐτός" "") (row 5 "τὸν" "" "ὁ" "") (row 6 "Σήθ" "." "Σήθ" "")))
       "After his begetting Seth.")
;; A gendered pronoun whose nearest agreeing noun is a thing is "it".
(check "feminine pronoun for a thing"
       (english "exod.20.8" (list (row 1 "τὴν" "" "ὁ" "") (row 2 "ἡμέραν" "" "ἡμέρα" "") (row 3 "ἁγιάζειν" "" "ἁγιάζω" "")
                                  (row 4 "αὐτήν" "." "αὐτός" "")))
       "The day to sanctify it.")

;; The segments keep every Greek word, in translation-file form.
(let ((sexp (call-with-values (lambda () (render-verse env "gen.1.3"
                                                      (list (row 1 "Γενηθήτω" "" "γίνομαι" "") (row 2 "φῶς" "." "φῶς" ""))
                                                      #t))
              (lambda (segs _) (segments->sexp env segs (make-hash-table))))))
  (check "segments" sexp '(("Let" (1 come-to-be "γίνομαι")) ("light" (2 light "φῶς")) ("come to be." (cont 1)))))

;; (verb "come back" "came back" ...) and (verb "come back" "came" ...) give
;; the particle once.
(for-each
 (lambda (v)
   (let* ((s (gloss-senses `((lemma "ἀναστρέφω" (sense return ,v (gloss "come back" "came back") (why "w"))))))
          (f (index-forms-rows '(("ἀνέστρεψεν" "ἀναστρέφω" "V-AAI-3S"))))
          (e (make-env f (make-hash-table) s '() (make-hash-table) (make-hash-table))))
     (check (format #f "particle once ~s" v)
            (call-with-values (lambda () (render-verse e "gen.8.9" (list (row 1 "ἀνέστρεψεν" "." "ἀναστρέφω" "")) #t))
              (lambda (segs _) (string-join (map car segs) " ")))
            "He/she/it came back.")))
 '((verb "come back" "came back" "come back") (verb "come back" "came" "come")))

;;; Real verses, rendered from the repository's data (form analyses,
;;; concordance, phrases) with NO overrides or pinned verses, so each check is
;;; the rules' own output. Expected English decided from the Greek in
;;; gsb/greek/01-gen.tsv.
(define real-env
  (call-with-values load-literal-env
    (lambda (e problems)
      (make-env (env-forms e) (env-nt e) (env-senses e) (env-phrases e) (make-hash-table) (make-hash-table)))))
(define gen-verses (append (read-greek-table "gsb/greek/01-gen.tsv") (read-greek-table "gsb/greek/02-exod.tsv")
                           (filter (lambda (v) (or (string-prefix? "lev.1." (car v)) (string-prefix? "deut.6." (car v))))
                                   (append (read-greek-table "gsb/greek/03-lev.tsv") (read-greek-table "gsb/greek/05-deut.tsv")))))
(define (prev-verse-words ref)
  ;; the verse before in the same chapter, as the generator passes it
  (let* ((chap (let ((p (string-split ref #\.))) (string-append (car p) "." (cadr p) ".")))
         (tail (member ref (map car gen-verses))))
    (let loop ((vs gen-verses) (prev #f))
      (cond ((null? vs) '())
            ((equal? (caar vs) ref) (if (and prev (string-prefix? chap (car prev))) (cdr prev) '()))
            (else (loop (cdr vs) (car vs)))))))
(define (gen ref)
  (call-with-values (lambda () (render-verse real-env ref (assoc-ref gen-verses ref) #t (prev-verse-words ref)))
    (lambda (segs stop?) (string-join (map car segs) " "))))
(define (has ref . parts)
  (let ((text (gen ref)))
    (for-each (lambda (p) (check (format #f "~a has ~s" ref p) (and (string-contains text p) #t) #t)) parts)))
(define (lacks ref . parts)
  (let ((text (gen ref)))
    (for-each (lambda (p) (check (format #f "~a lacks ~s (in ~s)" ref p text) (string-contains text p) #f)) parts)))

;; A1. μή opening a question expects "no": a plain yes/no question, not a negation.
(has "gen.18.14" "Is utterance impossible beside God?")
(has "gen.18.17" "Shall I hide from Abraham")
(has "gen.4.9" "am I guard of my brother?")
(has "gen.27.38" "Is one blessing to you, father?")
;; A2. Prohibitions: μή + second person subjunctive, no subject pronoun.
(has "gen.18.3" "do not pass by your servant")
(lacks "gen.18.3" "you do not pass")
(has "gen.19.7" "do not do evil")
(has "gen.19.17" "do not look around" "nor stand")
(has "gen.22.12" "Do not cast your hand upon the lad")
(has "gen.26.2" "Do not go down into Egypt")
(has "gen.3.1" "You will not eat at all")   ; οὐ μή is not a prohibition
;; μή + first/third person subjunctive, μή ποτε: "lest".
(has "gen.19.19" "lest the bad overtake me and I die")
(has "gen.20.2" "lest ever the men of the city kill him")
;; A3. The whole subject phrase moves, or nothing; never across a clause.
(has "gen.27.19" "And Jacob his son said to his father")
(has "gen.20.2" "But Abimelech king of Gerar sent and took Sarah")
(has "gen.21.22" "Abimelech and Ahuzzath his groomsman and Phicol the commander-in-chief of his power said to Abraham")
(has "gen.24.36" "And Sarah the woman of my")
(has "gen.24.12" "said, Lord the God of")          ; vocative not moved, no [the]
(has "gen.27.35" "Your brother having come with deceit took your blessing")
(has "gen.24.65" "But the servant said, This is my")
(lacks "gen.28.20" "I preserve")
(has "gen.9.22" "And Ham the father of Canaan saw the nakedness of his father")
(has "gen.9.23" "And Shem and Japheth having taken the garment")
(has "gen.7.21" "And every flesh moving upon the earth of the birds and the livestock and the beasts died")
(has "gen.10.10" "beginning of his/its kingdom came to be Babylon")
(has "gen.25.11" "God blessed Isaac his son")
(has "gen.26.5" "Abraham your father obeyed")
(has "gen.12.7" "Abram built there altar")
(has "gen.21.20" "but he came to be archer")       ; a person predicate gives the gender
(has "gen.20.7" "that he is prophet")
(has "gen.12.18" "that she is your woman")
(has "gen.20.9" "What [is] this you made to us?")
(has "gen.19.38" "But also the younger bore son")
(has "gen.8.9" "And the dove not having found rest")
(has "gen.12.11" "I know that")
(has "gen.19.13" "That we destroy this place")
(has "gen.22.12" "that you fear God")
(has "gen.4.26" "son came to be")                 ; a dative possessor: the person is the subject
(lacks "gen.22.1" "Abraham said")                 ; Ἀβραὰμ Ἀβραάμ is a call
(has "gen.27.1" "and called Esau his older son")  ; undecidable: Greek order, no false actor
(has "gen.27.18" "who are you, child?")
(has "gen.3.8" "both Adam and his woman hid")         ; ὅ τε X καὶ Y
(has "gen.18.4" "Let water be taken indeed")          ; past the particle δή
(has "gen.15.14" "after these they will go forth")    ; a preposition's object is no subject
(has "gen.14.16" "and Lot his brother he/she/it turned back") ; a fronted object with its apposition
(has "gen.18.10" "and Sarah your woman will have son") ; past a plain object
;; A4. Subjects of articular infinitives: possessive gerunds.
(has "gen.19.16" "in [the] Lord's sparing him")
(has "gen.19.29" "in [the] Lord's rubbing out all the cities" "in [the] Lord's overturning the cities")
(has "gen.13.14" "after Lot's being separated from him")
(has "gen.16.3" "of Abram's dwelling")
(has "gen.27.1" "after Isaac's growing old")
(has "gen.8.7" "until the water's being dried up from the earth")
(has "gen.19.19" "of my soul's living")
(has "gen.20.6" "of your not sinning into me")
(has "gen.28.15" "until my making all")
(has "gen.24.33" "until my speaking my utterances")
(has "gen.27.33" "before your going in")
(has "gen.11.2" "in their moving")
(has "gen.28.6" "in blessing him")                ; a transitive infinitive's pronoun is its object
;; A5. Genitive absolutes.
(has "gen.18.1" "he being seated upon the door")
(has "gen.24.30" "he having stood upon the camels")
(has "gen.25.6" "he further living")
;; B. Mechanics.
(lacks "gen.13.8" "Let  not")

;;; Second fix round (2026-11-28, ursinia-vff.47). Expected English decided
;;; from the Greek of each verse.
;; 1. A neuter plural subject takes a plural English verb, before or after it.
(has "gen.43.30" "for his bowels were being twisted together")    ; συνεστρέφετο τὰ ἔντερα αὐτοῦ
(has "gen.40.17" "the birds of the heaven were devouring them")    ; τὰ πετεινὰ ... κατήσθιεν αὐτά
(has "gen.49.24" "And their bows were crushed with might")         ; possessive not left behind
(has "gen.22.20" "Milcah and she has borne")                       ; καὶ αὐτή is not a second subject
;; 2. A name's case: apposition after a title or a preposition, an open dative.
(has "gen.35.9" "But God appeared to Jacob")                       ; Ὤφθη ... ὁ θεὸς Ἰακώβ
(has "gen.29.29" "But Laban gave to Rachel his daughter Bilhah")    ; Ῥαχὴλ τῇ θυγατρὶ αὐτοῦ
(has "gen.36.15" "chief Teman, chief Omar")                         ; ἡγεμών (apposition)
(has "gen.36.16" "these chiefs of Eliphaz")                         ; a plural title: genitive
(has "gen.29.18" "concerning Rachel your younger daughter")
(has "gen.45.21" "by Pharaoh the king")
(has "gen.49.29" "in the field of Ephron the Hittite")
(has "gen.25.9" "the field of Ephron of Zohar the Hittite")        ; τοῦ Σάαρ: his father
(has "gen.10.16" "And the Jebusite and the Amorite")               ; the article before a people
;; 3. The one pronoun of a transitive articular infinitive after a
;; preposition of time or a noun is its subject; bare τοῦ is a purpose.
(has "gen.38.17" "until your sending")                             ; ἕως τοῦ ἀποστεῖλαί σε
(has "gen.38.28" "in her bearing")                                 ; ἐν τῷ τίκτειν αὐτήν
(has "gen.25.24" "And the days of her bearing were filled")        ; with its noun when moved
(has "gen.39.15" "But in his hearing that")                        ; past δέ
(has "gen.41.32" "God will hurry to make it")                      ; purpose after the verb
(has "gen.4.15" "of not taking him away all the [one] finding him") ; a second accusative is the subject
(has "exod.20.20" "on account of testing you")                     ; ἕνεκεν: a purpose
;; 4. The subject phrase moves whole.
(has "gen.32.4" "So your servant Jacob says")                      ; ὁ παῖς σου Ἰακώβ
(has "gen.43.8" "and both we and you and our baggage may not die")
(has "gen.47.19" "and we and our earth will be servants of Pharaoh") ; the predicate stays
(has "gen.38.25" "these are")                                       ; ἐγώ is not ἐστιν's subject
(has "gen.43.27" "If your older father is healthy")                ; ὁ πατὴρ ὑμῶν ὁ πρεσβύτερος
;; 5. A negation stays with its verb when δέ/γάρ moves; ἄν with a past
;; indicative is "would have", with an optative "would".
(has "gen.40.23" "But the chief cupbearer did not remember Joseph")
(has "gen.8.21" "therefore I will not add further to strike")
(has "gen.43.10" "For if we did not delay, already we would have returned twice") ; the comma kept
(has "gen.31.27" "I would have sent you out")
(has "gen.44.8" "how would we steal")
(has "gen.6.4" "as ever the sons of God were entering")             ; ὡς ἄν: iterative
;; 6. κύριος: "Lord" in either case (Swete's capital marks only the
;; anarthrous name); a human lord is sense master, by data.
(has "gen.39.3" "Lord knew that [the] Lord with him")      ; no override: "Lord", no "[the]" after ὁ
(has "gen.32.4" "to my Lord Esau")
(let ((master-env (call-with-values load-literal-env
                    (lambda (e problems)
                      (let ((o (make-hash-table)))
                        (hash-set! o "gen.39.3#4" '((sense master)))
                        (hash-set! o "gen.32.4#8" '((sense master)))
                        (hash-set! o "gen.24.50#8" '((sense master)))
                        (make-env (env-forms e) (env-nt e) (env-senses e) (env-phrases e) o (make-hash-table)))))))
  (define (gen-m ref)
    (call-with-values (lambda () (render-verse master-env ref (assoc-ref gen-verses ref) #t (prev-verse-words ref)))
      (lambda (segs stop?) (string-join (map car segs) " "))))
  (check "gen.39.3 master" (and (string-contains (gen-m "gen.39.3") "lord knew that [the] Lord with him") #t) #t)
  (check "gen.32.4 master" (and (string-contains (gen-m "gen.32.4") "to my lord Esau") #t) #t)
  ;; master takes no supplied "[the]" (anarthrous Παρὰ κυρίου; God by default: "From [the] Lord")
  (check "gen.24.50 master no [the]" (string-contains (gen-m "gen.24.50") "[the] lord") #f))
(has "gen.24.50" "[the] Lord")
(has "gen.4.13" "to the Lord")                             ; πρὸς τὸν κύριον: no override
(has "gen.18.27" "to the Lord")
;; 7. Speech opening at a name, a hanging nominative, a capital after a
;; preposition or article (a name, not speech).
(has "gen.16.8" "said to her, Hagar maidservant of Sarai, from where do you come?")
(has "gen.17.15" "But God said to Abraham, Sarai your woman,")
(has "gen.24.40" "And he/she/it said to me, The Lord God,")
(has "gen.34.8" "And Hamor spoke to them saying, Shechem my son preferred")
(has "gen.30.13" "And Leah said, Happy I")
(has "gen.31.11" "according to sleep, Jacob Jacob.")
(has "gen.33.17" "And Jacob departs into Tents;")
(has "gen.42.22" "saying, Do not wrong the lad")                   ; nested: a prohibition
;; 8. First singular or third plural (ἔλαβον, ἴδον): by a cue in the sentence.
(has "gen.48.22" "which I took out of hand")                       ; ἐγώ
(has "gen.50.11" "And the inhabitants of the land of Canaan saw")  ; a plural nominative
(has "gen.12.15" "And the rulers of Pharaoh saw her")
;;; Third fix round (2026-11-28, ursinia-vff.55). Expected English decided
;;; from the Greek of each verse.
;; 1. Indeclinable names: after Κύριος ὁ θεός the genitive; one name is no
;; plural verb's subject; joined by καί to a dative, a dative.
(has "exod.5.1" "These the Lord God of Israel says")
(lacks "exod.28.3" "Aaron will make")
(has "exod.28.4" "to Aaron and to his sons")
(has "exod.8.5" "Say to Aaron your brother")                       ; after a second person verb
(has "exod.8.16" "Say to Aaron,")
(has "exod.10.26" "to serve the Lord our God")                     ; Κύριος ὁ θεὸς ἡμῶν
;; 2. A genitive pronoun after a verb taking the genitive is its object.
(has "exod.7.4" "And Pharaoh will not hearken to you")
(has "exod.6.12" "how will Pharaoh hearken to me?")
(has "exod.3.18" "they will hearken to your voice" "you and the senate of Israel will go in")
(has "gen.23.6" "but hear us." "in our choice tombs bury your dead" "no one of us")
(has "exod.2.6" "the daughter of Pharaoh spared him")               ; the object already there
;; 3. Third person imperatives.
(has "exod.5.7" "let them go and let them gather to themselves straws")
(has "exod.5.9" "let them care for these")
(has "exod.19.24" "but let not the priests and the people force")
(has "exod.34.3" "And let no one go up" "and let not the sheep and the oxen graze")
(has "exod.19.22" "And let the priests drawing near to the Lord God be sanctified")
(has "exod.36.6" "Let man and woman no longer work")
(has "gen.23.9" "let him/her/it give to me the double cave")
(has "gen.27.29" "And let nations slave for you")
(has "gen.1.20" "Let the waters bring out creeping things")
;; 4. Negation scope.
(has "exod.23.33" "they may not make")
(lacks "exod.23.33" "not to sin")
(has "exod.22.28" "you will not say badly.")
(has "exod.33.15" "If you yourself do not go, do not lead me up")
(has "exod.22.14" "but the Lord not be with him")                ; no override here: "Lord"
(has "exod.23.29" "so that the earth may not come to be wilderness")
(has "deut.6.12" "lest you forget")
(has "deut.6.14" "You do not go behind")
;; 5. Subject phrases with a numeral, πᾶς, a collective, ἕκαστος.
(has "exod.7.25" "And seven days were filled up")
(has "exod.21.18" "But if two men revile")
(has "exod.32.3" "And all the people took off the golden earrings")
(has "exod.12.6" "all the multitude of gathering of sons of Israel will slaughter it")
(has "exod.23.17" "every male of you will be seen")
(has "exod.11.2" "let each request")
;; 6. The rest.
(has "gen.13.12" "in land of Canaan")                               ; γῆ + a country
(has "exod.10.19" "in all land of Egypt")
(has "gen.21.23" "swear to me by God")                              ; oaths
(has "gen.22.16" "By myself I swore")
(has "gen.31.53" "swore by the fear")
(has "exod.2.10" "But the little child having grown up")            ; genitive absolutes
(has "gen.29.9" "Further he/it speaking to them")
(has "gen.44.4" "But they having gone forth the city")
(has "exod.19.4" "You yourselves have seen")                        ; the intensive αὐτός
(has "exod.20.23" "to you yourselves silver gods")
(has "exod.5.11" "collect to yourselves")
(has "exod.6.26" "Aaron and Moses, to whom")                       ; relatives
(has "gen.42.28" "What [is] this God made to us?")                  ; questions
(has "gen.37.10" "What [is] this dream which you dreamed?")
(has "exod.4.2" "What is this the [thing] in your hand?")
(has "exod.2.14" "Who installed you ruler")
(has "exod.25.11" "with pure gold")                                 ; with-adjective
(has "exod.30.19" "with water")
(has "exod.25.11" "you will gild over it")                          ; a thing from the verse before
(has "exod.3.22" "silver and golden gears")                         ; joined adjectives
;; 7. Legal and cultic prose.
(has "lev.1.9" "he/she/it is fruit offering")
(has "lev.1.9" "all the [things] upon the altar")
(has "deut.6.10" "And it will be whenever")
(has "deut.6.5" "out of your whole mind")
(has "exod.26.25" "And eight columns will be")
(lacks "exod.40.38" "he/she/it was fire")
;; Lettered chapters (Esther's additions).
(check "chapter-arg" (map chapter-arg '("12" "A" "0" "a" "AB")) '(12 "A" #f #f #f))
(check "literal-chapter-key" (map literal-chapter-key '("001.scm" "A.scm" "book.scm")) '(1 "A" #f))
(check "chapter<?" (sort (list "B" 3 "A" 1) chapter<?) '(1 3 "A" "B"))

(if (zero? failures)
    (format #t "gsb-literal: all checks pass~%")
    (begin (format #t "gsb-literal: ~a check(s) failed~%" failures) (exit 1)))
