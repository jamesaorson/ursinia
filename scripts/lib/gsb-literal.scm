;; Copyright (C) 2026
;;
;; The scripted hyper-literal layer of the Greek Source Bible (gsb/AGENTS.md
;; rule 16): English generated deterministically from the Greek table, our form
;; analyses (lemma + grammar tag), the concordance (gsb/lexicon/glosses/),
;; a few fixed phrases and hand-kept per-word overrides. Formats and the
;; rendering rules are documented in gsb/literal/README.md. Pure functions over
;; plain data, so scripts/lib/test/gsb-literal/test.scm can run them directly;
;; file I/O lives in scripts/gsb-literal.scm.

(define-module (scripts lib gsb-literal)
  #:use-module (scripts lib gsb)
  #:use-module (scripts lib gsb-translation)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-11)
  #:use-module (srfi srfi-13)
  #:use-module (ice-9 format)
  #:use-module (ice-9 ftw)
  #:use-module (ice-9 match)
  #:export (parse-tag
            load-literal-env
            literal-files
            literal-form-rows
            literal-override-forms
            literal-phrase-forms
            literal-chapter-path
            literal-chapter-key
            chapter-arg
            chapter<?
            choose-readings
            form-key
            env-pins
            explain-verse
            tag-field
            gloss-senses
            index-forms-rows
            index-nt-verses
            make-env
            render-verse
            verse-problems
            verse-warnings
            analyze-verse
            env-forms env-nt env-overrides env-phrases env-senses
            segments->sexp
            write-chapter
            english-past english-pp english-ing english-s3 english-plural suspicious-spelling? verb-heads
            normalize-for-compare))

;;; ---------------------------------------------------------------------------
;;; Grammar tags (Robinson codes, as in the New Testament tables;
;;; gsb/sources/nestle1904/parsing.txt)
;;; ---------------------------------------------------------------------------

(define %indeclinable '("PRI" "NUI" "LI" "OI"))

(define (parse-tag tag)
  "TAG as an alist: pos (string), and where present case, number, gender,
person, tense, voice, mood, degree (characters). #f for no tag."
  (and (string? tag) (not (string-null? tag))
       (match (string-split tag #\-)
         (("V" tvm . rest)
          (let ((tvm (string-trim tvm char-numeric?)))
            (append
             `((pos . "V") (tense . ,(string-ref tvm 0)) (voice . ,(string-ref tvm 1))
               (mood . ,(string-ref tvm 2)))
             ;; a trailing suffix (V-RAI-2P-ATT) is ignored
             (match rest
               (((? (lambda (s) (and (= 2 (string-length s)) (char-numeric? (string-ref s 0)))) pn) . _)
                `((person . ,(string-ref pn 0)) (number . ,(string-ref pn 1))))
               (((? (lambda (s) (= 3 (string-length s))) cng) . _)
                `((case . ,(string-ref cng 0)) (number . ,(string-ref cng 1)) (gender . ,(string-ref cng 2))))
               (_ '())))))
         (("S" (? (lambda (c) (= 5 (string-length c))) code) . _)
          ;; Possessive adjective S-1PASF: possessor person and number, then
          ;; case number gender; used like an adjective.
          `((pos . "A") (person . ,(string-ref code 0)) (case . ,(string-ref code 2))
            (number . ,(string-ref code 3)) (gender . ,(string-ref code 4))))
         (((and pos (or "P" "F")) code . _)
          ;; P-1NS / P-2GP (person case number), P-GSM (third person), F-3ASM.
          (let ((s (string-trim code char-numeric?))
                (person (if (char-numeric? (string-ref code 0)) (string-ref code 0) #\3)))
            `((pos . ,pos) (person . ,person) (case . ,(string-ref s 0)) (number . ,(string-ref s 1))
              ,@(if (> (string-length s) 2) `((gender . ,(string-ref s 2))) '()))))
         ((pos (? (lambda (c) (and (= 3 (string-length c)) (not (member c %indeclinable)))) cng) . suffix)
          `((pos . ,pos) (case . ,(string-ref cng 0)) (number . ,(string-ref cng 1)) (gender . ,(string-ref cng 2))
            ,@(match suffix (((? (lambda (s) (member s '("S" "C"))) d)) `((degree . ,(string-ref d 0)))) (_ '()))))
         ((pos . rest) `((pos . ,pos) (indeclinable . ,(pair? rest)))))))

(define (tag-field tp key) (and tp (assq-ref tp key)))

;;; ---------------------------------------------------------------------------
;;; English morphology
;;; ---------------------------------------------------------------------------

;; base past past-participle. ponytail: a closed list of English irregulars,
;; extended as glosses need them; a sense can also give (verb "base" "past" "pp").
(define %irregular
  '(("be" "was" "been") ("have" "had" "had") ("do" "did" "done") ("go" "went" "gone")
    ("come" "came" "come") ("become" "became" "become") ("make" "made" "made") ("say" "said" "said")
    ("see" "saw" "seen") ("give" "gave" "given") ("take" "took" "taken") ("eat" "ate" "eaten")
    ("know" "knew" "known") ("bring" "brought" "brought") ("find" "found" "found") ("grow" "grew" "grown")
    ("hide" "hid" "hidden") ("rise" "rose" "risen") ("begin" "began" "begun") ("bear" "bore" "borne")
    ("fly" "flew" "flown") ("sew" "sewed" "sewn") ("sow" "sowed" "sown") ("put" "put" "put")
    ("cast" "cast" "cast") ("set" "set" "set") ("leave" "left" "left") ("build" "built" "built")
    ("sleep" "slept" "slept") ("hear" "heard" "heard") ("send" "sent" "sent") ("shine" "shone" "shone")
    ("creep" "crept" "crept") ("fall" "fell" "fallen") ("stand" "stood" "stood") ("sit" "sat" "sat")
    ("lie" "lay" "lain") ("tell" "told" "told") ("think" "thought" "thought") ("keep" "kept" "kept")
    ("write" "wrote" "written") ("speak" "spoke" "spoken") ("strike" "struck" "struck")
    ("slay" "slew" "slain") ("swear" "swore" "sworn") ("dwell" "dwelt" "dwelt") ("feed" "fed" "fed")
    ("flee" "fled" "fled") ("lead" "led" "led") ("meet" "met" "met") ("pay" "paid" "paid")
    ("sell" "sold" "sold") ("buy" "bought" "bought") ("seek" "sought" "sought") ("teach" "taught" "taught")
    ("catch" "caught" "caught") ("fight" "fought" "fought") ("hold" "held" "held") ("lose" "lost" "lost")
    ("shut" "shut" "shut") ("smite" "smote" "smitten") ("steal" "stole" "stolen") ("throw" "threw" "thrown")
    ("wear" "wore" "worn") ("weep" "wept" "wept") ("drink" "drank" "drunk") ("sing" "sang" "sung")
    ("spring" "sprang" "sprung") ("run" "ran" "run") ("break" "broke" "broken") ("choose" "chose" "chosen")
    ("draw" "drew" "drawn") ("drive" "drove" "driven") ("forgive" "forgave" "forgiven") ("ride" "rode" "ridden")
    ("shake" "shook" "shaken") ("bind" "bound" "bound") ("hang" "hung" "hung") ("dig" "dug" "dug")
    ("lend" "lent" "lent") ("bend" "bent" "bent") ("let" "let" "let") ("cut" "cut" "cut")
    ("spread" "spread" "spread") ("get" "got" "gotten") ("overtake" "overtook" "overtaken")
    ("forsake" "forsook" "forsaken") ("kneel" "knelt" "knelt") ("beget" "begot" "begotten")
    ("arise" "arose" "arisen") ("awake" "awoke" "awoken") ("understand" "understood" "understood")
    ("withhold" "withheld" "withheld") ("bless" "blessed" "blessed") ("mean" "meant" "meant")
    ("rend" "rent" "rent") ("shoot" "shot" "shot") ("sweep" "swept" "swept") ("burn" "burned" "burned")
    ("show" "showed" "shown") ("fall" "fell" "fallen") ("undo" "undid" "undone")))

;; Final consonant doubled before -ed/-ing: by rule a one-syllable verb ending
;; consonant-vowel-consonant (blot, run, beg; not w, x, y: snow, fix, play);
;; longer verbs only when the stress is final, which spelling does not show,
;; so they are listed. %no-double: one-syllable exceptions.
(define %double '("permit" "commit" "admit" "submit" "occur" "prefer" "refer" "regret" "beget" "transfer"
                  "forget" "begin" "compel" "repel" "rebel" "control" "patrol" "equip" "omit" "upset" "abet" "befit"))
(define %no-double '())
;; Longer verbs ending consonant-vowel-consonant with the stress before the
;; end (no doubling): a -ing/-ed form of one not listed here or in %double is
;; a `check` warning, since spelling cannot show the stress.
(define %stress-initial
  '("open" "visit" "gather" "enter" "listen" "deliver" "remember" "number" "wander" "offer" "suffer" "murmur"
    "answer" "harden" "happen" "hearken" "travel" "marvel" "quarrel" "inherit" "inhabit" "covet" "summon" "reckon"
    "hasten" "scatter" "utter" "wonder" "order" "water" "honor" "cover" "consider" "worship" "fashion" "question"
    "strengthen" "dishonor" "fetter" "prosper" "ponder" "anger" "uncover" "sober"
    "interpret" "hunger" "plunder" "slaughter" "overpower" "loosen"))

(define (cvc-end? w)
  (let ((n (string-length w)))
    (and (>= n 3)
         (let ((c3 (string-ref w (- n 1))) (v (string-ref w (- n 2))) (c1 (string-ref w (- n 3))))
           (and (not (vowel? c3)) (not (memv c3 '(#\w #\x #\y))) (vowel? v) (not (vowel? c1)))))))

(define (verb-heads env)
  "The English head word of every concordance sense of a Greek verb (a lemma
in -ω, -μι, -μαι)."
  (let ((h (make-hash-table)))
    (hash-for-each
     (lambda (lemma senses)
       (when (any (lambda (e) (string-suffix? e lemma)) '("ω" "ώ" "μι" "μαι"))
         (for-each (lambda (s) (let ((g (car (verb-base s)))) (unless (string-null? g) (hash-set! h g #t)))) senses)))
     (env-senses env))
    h))

(define (suspicious-spelling? heads word)
  "WORD is the -ing/-ed form, undoubled, of a verb head (HEADS: verb-heads)
of more than one syllable ending consonant-vowel-consonant that neither
%double nor %stress-initial lists: whether its consonant doubles depends on
the stress, which spelling does not show (\"begeting\")."
  (let ((stem (cond ((string-suffix? "ing" word) (chop word 3))
                    ((string-suffix? "ed" word) (chop word 2))
                    (else #f))))
    (and stem (hash-ref heads stem) (cvc-end? stem)
         (string-index (substring stem 0 (- (string-length stem) 2)) vowel?)
         (not (member stem %double)) (not (member stem %stress-initial))
         #t)))

(define (doubles? w)
  (or (member w %double)
      (and (not (member w %no-double)) (>= (string-length w) 3)
           (let* ((n (string-length w)) (c3 (string-ref w (- n 1))) (v (string-ref w (- n 2))) (c1 (string-ref w (- n 3))))
             (and (not (vowel? c3)) (not (memv c3 '(#\w #\x #\y))) (vowel? v) (not (vowel? c1))
                  ;; one syllable: no other vowel before
                  (not (string-index (substring w 0 (- n 2)) (lambda (c) (or (vowel? c) (eqv? c #\y))))))))
      #f))

(define %irregular-plural
  '(("man" . "men") ("woman" . "women") ("child" . "children") ("foot" . "feet") ("tooth" . "teeth")
    ("ox" . "oxen") ("mouse" . "mice") ("sheep" . "sheep") ("fish" . "fish") ("livestock" . "livestock")
    ("deer" . "deer") ("leaf" . "leaves") ("wife" . "wives") ("knife" . "knives") ("life" . "lives")
    ("loaf" . "loaves") ("calf" . "calves") ("half" . "halves") ("self" . "selves") ("wolf" . "wolves")
    ("thief" . "thieves") ("cherub" . "cherubim") ("person" . "persons")))

(define (vowel? c) (memv c '(#\a #\e #\i #\o #\u)))
(define (ends? s suffix) (string-suffix? suffix s))
(define (cons-y? s) (and (ends? s "y") (> (string-length s) 1) (not (vowel? (string-ref s (- (string-length s) 2))))))
(define (chop s n) (substring s 0 (- (string-length s) n)))
(define (last-char s) (string (string-ref s (- (string-length s) 1))))

(define (english-s3 w)
  (cond ((string=? w "be") "is") ((string=? w "have") "has")
        ((cons-y? w) (string-append (chop w 1) "ies"))
        ((any (lambda (e) (ends? w e)) '("s" "x" "z" "ch" "sh" "o")) (string-append w "es"))
        (else (string-append w "s"))))

(define (regular-ed w)
  (cond ((ends? w "e") (string-append w "d"))
        ((cons-y? w) (string-append (chop w 1) "ied"))
        ((doubles? w) (string-append w (last-char w) "ed"))
        (else (string-append w "ed"))))

(define (english-past w) (let ((i (assoc w %irregular))) (if i (cadr i) (regular-ed w))))
(define (english-pp w) (let ((i (assoc w %irregular))) (if i (caddr i) (regular-ed w))))

(define (english-ing w)
  (cond ((string=? w "be") "being")
        ((ends? w "ie") (string-append (chop w 2) "ying"))
        ((and (ends? w "e") (not (any (lambda (e) (ends? w e)) '("ee" "ye" "oe"))) (> (string-length w) 2))
         (string-append (chop w 1) "ing"))
        ((doubles? w) (string-append w (last-char w) "ing"))
        (else (string-append w "ing"))))

(define (english-plural w)
  "Plural of the last word of the noun phrase W (\"fig tree\" -> \"fig trees\")."
  (let* ((parts (string-split w #\space))
         (lastw (last parts))
         (lower (string-downcase lastw))
         (pl (cond ((assoc lower %irregular-plural) => cdr)
                   ((cons-y? lower) (string-append (chop lastw 1) "ies"))
                   ((any (lambda (e) (ends? lower e)) '("s" "x" "z" "ch" "sh")) (string-append lastw "es"))
                   (else (string-append lastw "s")))))
    (string-join (append (drop-right parts 1) (list pl)) " ")))

;;; ---------------------------------------------------------------------------
;;; Concordance senses with the generator's optional fields
;;;
;;; (sense name (gloss ...) (why ...) [(verb "base" ["past" "pp"])] [(plural "x")]
;;;        [(voice active)] [(genitive "over")] [(dative "on")] [(subject "it")])
;;; ---------------------------------------------------------------------------

(define (gloss-senses forms)
  "Hash lemma -> list of (name . fields), FIELDS an alist of the sense's items."
  (let ((h (make-hash-table)))
    (for-each (match-lambda
                (('lemma lemma senses ...)
                 (hash-set! h (string-normalize-nfc lemma)
                            (filter-map (match-lambda
                                          (('sense name items ...)
                                           (cons name (filter-map (lambda (i) (and (pair? i) (symbol? (car i)) (cons (car i) (cdr i)))) items)))
                                          (_ #f))
                                        senses)))
                (_ #f))
              forms)
    h))

(define (sense-of env lemma name)
  "(name . fields) for LEMMA's sense NAME (#f = default, the first), or #f."
  (let ((senses (and lemma (hash-ref (env-senses env) lemma))))
    (and (pair? senses) (if name (assq name senses) (car senses)))))

(define (field sense key) (and sense (assq-ref (cdr sense) key)))
(define (field1 sense key) (let ((f (field sense key))) (and (pair? f) (car f))))
(define (gloss-list sense) (or (field sense 'gloss) '()))
(define (gloss1 sense) (let ((g (gloss-list sense))) (if (pair? g) (car g) "")))

;;; ---------------------------------------------------------------------------
;;; Environment: form analyses, phrases, overrides, concordance
;;; ---------------------------------------------------------------------------

;; forms: spelling-key -> list of (lemma tag sense-or-#f), ours replace the
;; New Testament's. nt: spelling-key -> list of (lemma tag #f), most frequent
;; first. overrides: "ref#n" -> alist; pins: "ref" -> segments.
(define (form-key s)
  "How forms are matched: NFC, lowercase, grave as acute, an enclitic's thrown
back accent dropped (σπέρματός = σπέρματος)."
  (drop-throwback (spelling-key (string-normalize-nfc s))))

(define (make-env forms nt senses phrases overrides pins)
  (list forms nt senses phrases overrides pins))
(define (env-forms e) (first e))
(define (env-nt e) (second e))
(define (env-senses e) (third e))
(define (env-phrases e) (fourth e))
(define (env-overrides e) (fifth e))
(define (env-pins e) (sixth e))

;;; The data files (gsb/literal/README.md).

(define %literal-dir "gsb/literal")

(define (literal-files sub suffix)
  "Sorted paths of gsb/literal/SUB/*SUFFIX."
  (let ((dir (string-append %literal-dir "/" sub)))
    (if (file-exists? dir)
        (map (lambda (f) (string-append dir "/" f))
             (sort (or (scandir dir (lambda (f) (string-suffix? suffix f))) '()) string<?))
        '())))

(define (literal-form-rows)
  "(values rows problems): every data row of gsb/literal/forms/*.tsv as
(path form lemma tag sense note), and problems (short rows, a form in two files)."
  (let ((seen (make-hash-table)) (problems '()))
    (let ((rows
           (append-map
            (lambda (path)
              (filter-map
               (lambda (line)
                 (let ((cols (split-tab line)))
                   (cond ((or (string-prefix? "#" line) (equal? (car cols) "form")) #f)
                         ((< (length cols) 3)
                          (set! problems (cons (format #f "~a: row ~s needs at least form, lemma, tag" path line) problems)) #f)
                         (else
                          (let* ((k (form-key (car cols))) (other (hash-ref seen k)))
                            (if (and other (not (equal? other path)))
                                (set! problems (cons (format #f "~a: form ~a is already analyzed in ~a; keep a form's readings in one file" path (car cols) other) problems))
                                (hash-set! seen k path)))
                          (cons path (take (append cols (list "" "" "")) 5))))))
               (cdr (read-lines path))))
            (literal-files "forms" ".tsv"))))
      (values rows (reverse problems)))))

(define (literal-override-forms)
  "(values forms problems): every form of gsb/literal/overrides/*.scm as
(path . form), and problems with their shape."
  (let ((problems '()))
    (let ((forms
           (append-map
            (lambda (path)
              (filter-map
               (lambda (f)
                 (match f
                   (('word (? string? at) items ...) (cons path f))
                   (('verse (? string? ref) items ...)
                    (if (and (assq 'literal items) (assq 'why items))
                        (cons path f)
                        (begin (set! problems (cons (format #f "~a: pinned verse ~a needs (literal seg ...) and (why \"reason\")" path ref) problems)) #f)))
                   (x (set! problems (cons (format #f "~a: expected (word \"ref#n\" ...) or (verse \"ref\" ...), got ~s" path x) problems)) #f)))
               (read-forms path)))
            (literal-files "overrides" ".scm"))))
      (values forms (reverse problems)))))

(define (literal-phrase-forms)
  (let ((p (string-append %literal-dir "/phrases.scm"))) (if (file-exists? p) (read-forms p) '())))

(define* (load-literal-env #:key nt-tables)
  "(values env problems) from gsb/literal/, the concordance and the New
Testament tables (NT-TABLES: lists of read-greek-table verses, read from
gsb/greek when not given)."
  (let*-values (((rows p1) (literal-form-rows))
                ((ovs p2) (literal-override-forms)))
    (let ((words (make-hash-table)) (pins (make-hash-table))
          (nt (index-nt-verses
               (or nt-tables
                   (filter-map (lambda (b) (and (equal? (book-field b 'testament) "NT")
                                                (file-exists? (greek-table-path b))
                                                (read-greek-table (greek-table-path b))))
                               (read-books))))))
      (for-each (match-lambda
                  ((_ 'word at items ...) (hash-set! words at items))
                  ((_ 'verse ref items ...) (hash-set! pins ref (cdr (assq 'literal items)))))
                ovs)
      (values (make-env (index-forms-rows (map cdr rows)) nt (gloss-senses (read-gloss-forms))
                        (literal-phrase-forms) words pins)
              (append p1 p2)))))

;;; Chapters are numbers, or a capital letter for Esther's Greek additions
;;; (refs esth.A.1 ... esth.F.11): the generated file is 001.scm, or A.scm.

(define (chapter-file-stem chapter)
  (if (number? chapter) (format #f "~3,'0d" chapter) chapter))

(define (literal-chapter-path book chapter)
  (format #f "~a/~a/~a.scm" %literal-dir (book-file-stem book) (chapter-file-stem chapter)))

(define (literal-chapter-key name)
  "The chapter of a generated file name: 001.scm -> 1, A.scm -> \"A\", else #f."
  (cond ((chapter-file-number name) => identity)
        ((and (= (string-length name) 5) (string-suffix? ".scm" name) (char-upper-case? (string-ref name 0))
              (char<=? #\A (string-ref name 0) #\Z))
         (substring name 0 1))
        (else #f)))

(define (chapter-arg s)
  "A chapter as given on the command line or in a ref: a positive number, or
one capital letter (a lettered addition, Esther A-F); #f otherwise."
  (let ((n (string->number s)))
    (cond ((and n (exact-integer? n) (> n 0)) n)
          ((and (= (string-length s) 1) (char<=? #\A (string-ref s 0) #\Z)) s)
          (else #f))))

(define (chapter<? a b)
  "Numbered chapters in order, then lettered ones alphabetically."
  (cond ((and (number? a) (number? b)) (< a b))
        ((number? a) #t)
        ((number? b) #f)
        (else (string<? a b))))

(define (index-forms-rows rows)
  "ROWS: lists (form lemma tag sense note) from gsb/literal/forms/*.tsv. Hash
spelling-key -> readings in row order."
  (let ((h (make-hash-table)))
    (for-each (match-lambda
                ((form lemma tag . rest)
                 (let ((k (form-key form))
                       (sense (match rest (((? (lambda (s) (not (string-null? s))) s) . _) (string->symbol s)) (_ #f))))
                   (hash-set! h k (append (hash-ref h k '())
                                          (list (list (string-normalize-nfc lemma) tag sense)))))))
              rows)
    h))

(define (index-nt-verses tables)
  "TABLES: lists of verses (read-greek-table) of New Testament books. Hash
spelling-key -> (lemma tag #f) readings, most frequent first."
  (let ((counts (make-hash-table)))
    (for-each (lambda (verses)
                (for-each (lambda (v)
                            (for-each (lambda (w)
                                        (unless (string-null? (word-morph* w))
                                          (let* ((k (form-key (word-text* w)))
                                                 (h (or (hash-ref counts k) (let ((h (make-hash-table))) (hash-set! counts k h) h)))
                                                 (r (list (word-lemma* w) (word-morph* w))))
                                            (hash-set! h r (+ 1 (hash-ref h r 0))))))
                                      (cdr v)))
                          verses))
              tables)
    (let ((out (make-hash-table)))
      (hash-for-each (lambda (k h)
                       (hash-set! out k (map (lambda (p) (append (car p) '(#f)))
                                             (sort (hash-map->list cons h)
                                                   (lambda (a b) (or (> (cdr a) (cdr b))
                                                                     (and (= (cdr a) (cdr b)) (string<? (cadar a) (cadar b)))))))))
                     counts)
      out)))

;;; ---------------------------------------------------------------------------
;;; Units: one per Greek word (or fixed phrase), as functional alists
;;; ---------------------------------------------------------------------------

(define (u x key) (let ((p (assq key x))) (and p (cdr p))))
(define (u+ x . kvs)
  (let loop ((kvs kvs) (x x))
    (if (null? kvs) x (loop (cddr kvs) (cons (cons (car kvs) (cadr kvs)) (alist-delete (car kvs) x eq?))))))

(define (tp x) (u x 'tp))
(define (pos x) (tag-field (tp x) 'pos))
(define (case-of x) (tag-field (tp x) 'case))
(define (num-of x) (tag-field (tp x) 'number))
(define (gen-of x) (tag-field (tp x) 'gender))
(define (mood x) (tag-field (tp x) 'mood))
(define (lemma x) (u x 'lemma))
(define (is? x . poss) (and x (member (pos x) poss) #t))
(define (participle? x) (and (is? x "V") (eqv? (mood x) #\P)))
(define (infinitive? x) (and (is? x "V") (eqv? (mood x) #\N)))
(define (finite? x) (and (is? x "V") (memv (mood x) '(#\I #\S #\O #\M)) #t))
(define (nominal? x) (or (is? x "N" "A" "T" "D" "P" "F" "R" "I" "X" "K" "S") (participle? x)))
(define (agree? a b)
  (and a b (case-of a) (eqv? (case-of a) (case-of b)) (eqv? (num-of a) (num-of b))
       (or (not (gen-of a)) (not (gen-of b)) (eqv? (gen-of a) (gen-of b)))))
(define (lemma-in? x . ls) (and x (member (lemma x) ls) #t))
(define %numeral-lemmas '("εἷς" "δύο" "τρεῖς" "τέσσαρες" "πέντε" "ἕξ" "ἑπτά" "ὀκτώ" "ἐννέα" "δέκα"))
(define (numeral? x)
  (and x (is? x "A") (or (apply lemma-in? x %numeral-lemmas) (equal? (u x 'tag) "A-NUI")
                         (and (string? (lemma x)) (or (string-suffix? "κόσιοι" (lemma x)) (string-suffix? "χίλιοι" (lemma x))))
                         (and (string? (u x 'tag)) (string-suffix? "-NUI" (u x 'tag))))
       #t))

(define (capital? s)
  (let ((c (string-index s char-alphabetic?)))
    (and c (char-upper-case? (string-ref s c)) (not (all-caps? s)))))

;;; ---------------------------------------------------------------------------
;;; Choosing one analysis per word
;;; ---------------------------------------------------------------------------

(define %prep-case
  '(("ἐν" . #\D) ("εἰς" . #\A) ("ἐκ" . #\G) ("ἀπό" . #\G) ("σύν" . #\D) ("πρό" . #\G)
    ("πρός" . #\A) ("ἕως" . #\G) ("πλήν" . #\G) ("ἐπάνω" . #\G) ("ὑποκάτω" . #\G) ("ἀντί" . #\G) ("ἀπέναντι" . #\G)
    ("κατέναντι" . #\G) ("ἔμπροσθεν" . #\G) ("ὀπίσω" . #\G) ("χωρίς" . #\G) ("ἕνεκα" . #\G)))

(define (reading-case r) (tag-field (parse-tag (second r)) 'case))
(define (readings-agree? a b)
  (let ((ta (parse-tag (second a))) (tb (parse-tag (second b))))
    (and ta tb (tag-field ta 'case)
         (eqv? (tag-field ta 'case) (tag-field tb 'case))
         (eqv? (tag-field ta 'number) (tag-field tb 'number))
         (or (not (tag-field tb 'gender)) (eqv? (tag-field ta 'gender) (tag-field tb 'gender))))))

(define (word-readings env ref w)
  "Candidate readings (lemma tag sense) of word row W: an override's, ours,
the New Testament's, else the table's lemma with no tag."
  (let* ((o (hash-ref (env-overrides env) (format #f "~a#~a" ref (word-n w))))
         (key (form-key (word-text* w)))
         (base (or (hash-ref (env-forms env) key)
                   (hash-ref (env-nt env) key)
                   (if (string-null? (word-lemma* w)) '() (list (list (word-lemma* w) #f #f))))))
    (if (and o (or (assq 'tag o) (assq 'lemma o)))
        (list (list (or (and (assq 'lemma o) (cadr (assq 'lemma o)))
                        (and (pair? base) (first (car base)))
                        (word-lemma* w))
                    (or (and (assq 'tag o) (cadr (assq 'tag o))) (and (pair? base) (second (car base))))
                    #f))
        base)))

(define (choose-readings env ref words)
  "One reading per word: the first candidate, preferring the case a preceding
preposition governs and an article/next-word pair that agrees."
  (let* ((cands (list->vector (map (lambda (w) (accusative-first (word-readings env ref w))) words)))
         (n (vector-length cands)))
    ;; Preposition case: applies to the words of the following noun phrase.
    (let loop ((i 0) (gov #f))
      (when (< i n)
        (let* ((cs (vector-ref cands i))
               (c0 (and (pair? cs) (car cs)))
               (pref (if gov (filter (lambda (r) (eqv? (reading-case r) gov)) cs) '())))
          (when (pair? pref) (vector-set! cands i (append pref (lset-difference equal? cs pref))))
          (let ((p (and c0 (tag-field (parse-tag (second c0)) 'pos))))
            (loop (+ i 1)
                  (cond ((and c0 (assoc (first c0) %prep-case)) => cdr)
                        ((member p '("T" "A")) gov)
                        (else #f)))))))
    (define (pos-of cs) (and (pair? cs) (tag-field (parse-tag (second (car cs))) 'pos)))
    (define (agree-with! i fixed)
      ;; Put word I's first reading agreeing with reading FIXED in front.
      (let ((x (find (lambda (r) (readings-agree? fixed r)) (vector-ref cands i))))
        (and x (vector-set! cands i (cons x (delete x (vector-ref cands i)))) #t)))
    ;; Article + next word, both chosen to agree (τὸ φῶς).
    (do ((i 0 (+ i 1))) ((>= i (- n 1)))
      (let* ((j (let skip ((j (+ i 1)))
                  ;; past δέ, γάρ: τῷ δὲ τρισκαιδεκάτῳ ἔτει
                  (if (and (< (+ j 1) n) (member (form-key (word-text* (list-ref words j))) '("δε" "δὲ" "δέ" "γαρ" "γάρ" "μεν" "μέν" "οὖν" "ουν")))
                      (skip (+ j 1))
                      j)))
             (a (vector-ref cands i)) (b (vector-ref cands j)))
        (when (and (pair? a) (pair? b) (equal? (pos-of a) "T"))
          (let ((pair (any (lambda (x) (any (lambda (y) (and (readings-agree? x y) (cons x y))) b)) a))
                (prev (and (> i 0) (pair? (vector-ref cands (- i 1))) (car (vector-ref cands (- i 1))))))
            (cond
             (pair
              (vector-set! cands i (cons (car pair) (delete (car pair) a)))
              (vector-set! cands j (cons (cdr pair) (delete (cdr pair) b))))
             ;; An attributive article before a preposition or adverb agrees
             ;; with the noun before it: τοῦ ὕδατος τοῦ ἐπάνω.
             ((and prev (find (lambda (x) (readings-agree? prev x)) a))
              => (lambda (x) (vector-set! cands i (cons x (delete x a))))))))))
    ;; Then a word before an article agrees with it (πάντων τῶν), and a word
    ;; after an adjective or noun agrees with that (χόρτον χλωρόν).
    (do ((i 0 (+ i 1))) ((>= i (- n 1)))
      (let ((a (vector-ref cands i)) (b (vector-ref cands (+ i 1))))
        (when (and (pair? a) (pair? b))
          (cond ((and (equal? (pos-of b) "T") (member (pos-of a) '("A" "D")))
                 (agree-with! i (car b)))
                ;; adjective + noun: the adjective follows the noun if it can
                ((and (member (pos-of a) '("A" "D")) (equal? (pos-of b) "N"))
                 (or (agree-with! i (car b)) (agree-with! (+ i 1) (car a))))
                ((and (member (pos-of a) '("A" "D" "N")) (member (pos-of b) '("A" "D" "N" "V")))
                 (agree-with! (+ i 1) (car a)))))))
    ;; ὅ τε: the article accented before the enclitic, not the relative.
    (do ((i 0 (+ i 1))) ((>= i (- n 1)))
      (when (equal? (form-key (word-text* (list-ref words (+ i 1)))) "τε")
        (let ((t (find (lambda (r) (equal? (first r) "ὁ")) (vector-ref cands i))))
          (when t (vector-set! cands i (cons t (delete t (vector-ref cands i))))))))
    ;; After ἵνα, ἐάν, μή ... (to the next punctuation) a subjunctive reading
    ;; wins: φάγῃ is future "you will eat", but μή ... φάγῃ "he eat".
    (let loop ((ws words) (i 0) (subj? #f))
      (unless (null? ws)
        (let* ((cs (vector-ref cands i))
               (s (filter (lambda (r) (eqv? #\S (tag-field (parse-tag (second r)) 'mood))) cs)))
          (when (and subj? (pair? s)) (vector-set! cands i (append s (lset-difference equal? cs s))))
          (loop (cdr ws) (+ i 1)
                (and (string-null? (word-post* (car ws)))
                     (or subj? (and (pair? cs) (member (first (car cs)) '("ἵνα" "ἐάν" "ἄν" "ὅταν" "μή" "ὅπως")) #t)))))))
    (person-1s-3p! words cands)
    (map (lambda (cs) (if (pair? cs) (car cs) #f)) (vector->list cands))))

(define (reading-person-number r)
  (let ((t (parse-tag (second r)))) (and t (equal? (tag-field t 'pos) "V") (list (tag-field t 'person) (tag-field t 'number)))))

(define (person-1s-3p! words cands)
  "ἔλαβον, ἴδον, ἦλθον, ἔφαγον: one spelling for the first singular and the
third plural. Inside its sentence (and its side of a speech opening), ἐγώ
decides 1S; a nominative plural (not a preposition's), or a verb before it
joined by καί, decides by its person and number. With no cue the first
reading stays and the word is marked (a fourth element 'person-unsure) for
`check` (person-unsure): never a silent guess."
  (let* ((n (vector-length cands)) (ws (list->vector words)))
    (define (first-reading i) (let ((cs (vector-ref cands i))) (and (pair? cs) (car cs))))
    (define (key i) (form-key (word-text* (vector-ref ws i))))
    (define (speech-start? i)
      ;; a capital on a common word after the first: Swete's speech opening
      (and (> i 0) (let ((r (first-reading i))) (and r (lower-cap? (word-text* (vector-ref ws i)) (first r))))))
    (define (amb? k)
      (let ((cs (vector-ref cands k)))
        (and (any (lambda (r) (equal? (reading-person-number r) '(#\1 #\S))) cs)
             (any (lambda (r) (equal? (reading-person-number r) '(#\3 #\P))) cs))))
    (do ((i 0 (+ i 1))) ((>= i n))
      (let* ((cs (vector-ref cands i))
             (s1 (find (lambda (r) (equal? (reading-person-number r) '(#\1 #\S))) cs))
             (p3 (find (lambda (r) (equal? (reading-person-number r) '(#\3 #\P))) cs)))
        (when (and s1 p3 (equal? (first s1) (first p3)))
          (let* ((start (let back ((k i))
                          (if (and (> k 0) (not (strong-stop? (word-post* (vector-ref ws (- k 1))))) (not (speech-start? k)))
                              (back (- k 1)) k)))
                 (end (let fwd ((k (+ i 1)))
                        (if (and (< k n) (not (strong-stop? (word-post* (vector-ref ws (- k 1))))) (not (speech-start? k)))
                            (fwd (+ k 1)) k)))
                 ;; (forward only to the next finite verb or καί: ἴδον ... καὶ ὥσπερ
                 ;; ἑπτὰ στάχυες ἀνέβαινον is another clause)
                 (end (let fwd ((k (+ i 1)))
                        (if (and (< k end) (not (member (key k) '("και" "καὶ" "καί")))
                                 (not (let ((r (first-reading k))) (and r (finite-reading? r)))))
                            (fwd (+ k 1)) k)))
                 (region (remove (lambda (k) (= k i)) (iota (- end start) start)))
                 (ego? (any (lambda (k) (member (key k) '("ἐγω" "ἐγώ" "κἀγω" "κἀγώ"))) region))
                 (plural-nom? (any (lambda (k)
                                     (let ((r (first-reading k)) (p (and (> k 0) (first-reading (- k 1)))))
                                       (and r (let ((t (parse-tag (second r))))
                                                (and t (eqv? (tag-field t 'case) #\N) (eqv? (tag-field t 'number) #\P)
                                                     (not (eqv? (tag-field t 'gender) #\N))
                                                     (not (member (tag-field t 'pos) '("P"))))) ; (ἡμεῖς is 1P)
                                            (not (and p (assoc (first p) %prep-case))))))
                                   region))
                 ;; καὶ ἔλαβον after a verb of the sentence: its person/number
                 (joined (and (> i 0) (member (key (- i 1)) '("και" "καὶ" "καί"))
                              (let back ((k (- i 2)))
                                (and (>= k start)
                                     (let ((pn (let ((r (first-reading k))) (and r (finite-reading? r) (reading-person-number r)))))
                                       (cond ((not pn) (back (- k 1)))
                                             ;; (not a verb inside a subordinate clause: ἡνίκα
                                             ;; ἐνεκίσσων τὰ πρόβατα, καὶ ἴδον "I saw")
                                             ((let sub ((m (- k 1)))
                                                (and (>= m start) (not (member (key m) '("και" "καὶ" "καί")))
                                                     (or (let ((r (first-reading m)))
                                                           (and r (or (member (first r) %clause-openers) (member (first r) %subordinators)
                                                                      (equal? (tag-field (parse-tag (second r)) 'pos) "R"))))
                                                         (sub (- m 1)))))
                                              #f)
                                             (else pn)))))))
                 (pn-in (lambda (ks pred) (any (lambda (k) (let ((r (first-reading k))) (and r (pred (parse-tag (second r)))))) ks)))
                 ;; ἔλαβον Ἀβρὰμ καὶ Ναχώρ: two names joined by καί after it;
                 ;; ἑαυτοῖς: a third plural reflexive
                 (names-joined? (and (< (+ i 3) n)
                                     (let ((a (first-reading (+ i 1))) (c (first-reading (+ i 3))))
                                       (and a c (equal? (second a) "N-PRI") (equal? (second c) "N-PRI")
                                            (member (key (+ i 2)) '("και" "καὶ" "καί"))))))
                 (refl-3p? (pn-in region (lambda (t) (and t (equal? (tag-field t 'pos) "F") (eqv? (tag-field t 'person) #\3) (eqv? (tag-field t 'number) #\P)))))
                 ;; narrative: no first or second person word anywhere in the
                 ;; verse and no speech opening in it (inside speech "I" and
                 ;; "they" are both common: undecided)
                 (narrative? (and (not (any speech-start? (iota n)))
                                  (not (pn-in (remove (lambda (k) (or (= k i) (amb? k))) (iota n))
                                              (lambda (t) (and t (memv (tag-field t 'person) '(#\1 #\2))
                                                               (not (equal? (tag-field t 'pos) "S"))))))))
                 (choice (cond (ego? s1)
                               ((or plural-nom? names-joined? refl-3p?) p3)
                               ((equal? joined '(#\1 #\S)) s1)
                               ((equal? joined '(#\3 #\P)) p3)
                               (else #f))))
            ;; With no cue: in a verse with no first or second person word
            ;; (narrative, unless the speech began in an earlier verse) the
            ;; third plural, else the first form row; both marked for check.
            (vector-set! cands i
                         (cond (choice (cons choice (delete choice cs)))
                               (narrative? (cons (append (take p3 3) '(person-unsure)) (delete p3 cs)))
                               (else (cons (append (take (car cs) 3) '(person-unsure)) (cdr cs)))))))))))

(define (finite-reading? r)
  (let ((t (parse-tag (second r)))) (and t (equal? (tag-field t 'pos) "V") (memv (tag-field t 'mood) '(#\I #\S #\O #\M)) #t)))

(define (accusative-first readings)
  "Neuter nominative and accusative look alike: a neuter nominative reading
goes after its accusative twin; the subject rules decide when it is the
subject."
  (define (twin? n a)
    (let ((tn (parse-tag (second n))) (ta (parse-tag (second a))))
      (and tn ta (equal? (first n) (first a)) (eqv? (tag-field tn 'case) #\N) (eqv? (tag-field tn 'gender) #\N)
           (eqv? (tag-field ta 'case) #\A) (equal? (alist-delete 'case tn) (alist-delete 'case ta)))))
  (let ((late (filter (lambda (r) (any (lambda (o) (twin? r o)) readings)) readings)))
    (append (lset-difference equal? readings late) late)))

;;; ---------------------------------------------------------------------------
;;; Rendering one verse
;;; ---------------------------------------------------------------------------

(define (override env ref n key)
  (let* ((o (hash-ref (env-overrides env) (format #f "~a#~a" ref n)))
         (f (and o (assq key o))))
    (and f (cadr f))))

(define (lower-cap? text lem)
  "TEXT is capitalized though its lemma is not (and is not Κύριος): Swete's
capital for a paragraph or direct speech, not for a name."
  (and (capital? text) (string? lem) (not (string-null? lem))
       (char-lower-case? (string-ref lem 0)) (not (equal? lem "κύριος"))))

(define (base-units env ref words)
  (map (lambda (w r i)
         (let* ((n (word-n w))
                (o-sense (override env ref n 'sense))
                (lem (if r (string-normalize-nfc (first r)) (word-lemma* w)))
                (tag (and r (second r))))
           `((n . ,n) (refs . ((,n ,(or o-sense (and r (third r))) ,lem))) (sense . ,(or o-sense (and r (third r))))
             (lemma . ,lem) (tag . ,tag) (tp . ,(parse-tag tag))
             (table-lemma . ,(word-lemma* w))
             (greek . ,(word-text* w)) (pre . ,(word-pre* w)) (post . ,(word-post* w))
             (cap . ,(capital? (word-text* w))) (idx . ,i) (helper . "")
             ;; A capital on a common word (not a name, not Κύριος) opens
             ;; direct speech in Swete: "said, Let".
             (lower-cap . ,(lower-cap? (word-text* w) lem))
             (person-unsure . ,(and r (> (length r) 3)))
             ;; Swete prints Κύριος with a capital for God and κύριος in lower
             ;; case for a human lord or master: "lord", no supplied "[the]"
             (human-lord . ,(and (equal? lem "κύριος")
                                 (let ((c (string-index (word-text* w) char-alphabetic?)))
                                   (and c (char-lower-case? (string-ref (word-text* w) c))))))
             ;; also a capital vocative (εἶπεν Κύριε): its capital is the speech's
             (speech . ,(and (> i 0) (or (lower-cap? (word-text* w) lem)
                                         (and (capital? (word-text* w)) (eqv? (tag-field (parse-tag tag) 'case) #\V)
                                              ;; not inside speech: Δέσποτα Κύριε; Μή τι, Κύριε
                                              ;; (after another vocative: assign-roles)
                                              (string-null? (word-post* (list-ref words (- i 1))))))))
             (english . ,(override env ref n 'english))
             (before . ,(override env ref n 'before))
             (after . ,(override env ref n 'after))
             (subject . ,(override env ref n 'subject)))))
       words (choose-readings env ref words) (iota (length words))))

(define (ref-sense* r) (second r))
(define (unit-sense env x) (sense-of env (lemma x) (u x 'sense)))
(define (set-sense x name)
  (u+ x 'sense name 'refs (cons (list (first (car (u x 'refs))) name (third (car (u x 'refs)))) (cdr (u x 'refs)))))

;; Fixed phrases: (phrase (lemmas "ἀνά" "μέσος") (senses meson between)
;;                 (english "between") [(tag "PREP")] (why "..."))
(define (phrase-field p key) (let ((f (assq key (cdr p)))) (and f (cdr f))))

(define (collapse-phrases env units)
  (let loop ((us units) (acc '()))
    (if (null? us)
        (reverse acc)
        (let ((m (find (lambda (p)
                         (let ((ls (phrase-field p 'lemmas)))
                           (and (<= (length ls) (length us))
                                ;; Κύριε ὁ θεός: a vocative is not the name phrase
                                (not (eqv? (case-of (car us)) #\V))
                                (every (lambda (l x) (equal? (string-normalize-nfc l) (lemma x))) ls (take us (length ls))))))
                       (env-phrases env))))
          (if (not m)
              (loop (cdr us) (cons (car us) acc))
              (let* ((k (length (phrase-field m 'lemmas)))
                     (parts (take us k))
                     ;; the grammar of the whole is its last noun's (θεός in Κύριος ὁ θεός σου)
                     (head (or (find (lambda (x) (is? x "N")) (reverse parts)) (last parts)))
                     (tag (or (and (phrase-field m 'tag) (car (phrase-field m 'tag))) (u head 'tag))))
                (loop (drop us k)
                      (cons (u+ (car parts)
                                'refs (map (lambda (x s) (list (u x 'n) s (lemma x))) parts (phrase-field m 'senses))
                                'lemma (lemma head) 'sense (list-ref (phrase-field m 'senses) (list-index (lambda (x) (eq? x head)) parts))
                                'tag tag 'tp (parse-tag tag)
                                'post (u (last parts) 'post) 'fixed (car (phrase-field m 'english))
                                'phrase #t 'phrase-prep (is? (car parts) "PREP"))
                            acc))))))))

(define (name-like? env x)
  (and (is? x "N") (memv (num-of x) '(#\S #f))
       (let ((s (unit-sense env x)))
         (and s (or (eq? (car s) 'name) (equal? (lemma x) "θεός"))
              (string-index (gloss1 s) char-upper-case?) #t))))

(define (apposition-case env t n)
  "The case of article T + person noun N (not a name) in apposition after a
name, or #f."
  (and t n (is? t "T") (case-of t) (is? n "N") (agree? t n) (or (not (name-like? env n)) (gentilic? env n)) (person-noun? env n)
       (case-of t)))

(define (gentilic? env x)
  "X names a people or one of it (Χετταῖος \"Hittite\", Αἰγυπτία \"Egyptian\"):
its gloss ends -ite, -ian or -ean. ponytail: by the English gloss; a
(gentilic) field if a people's name ever ends otherwise."
  (let ((g (gloss1 (or (unit-sense env x) '(#f)))))
    ;; (declined: Μαδιάμ "Midian" is a name)
    (and (name-like? env x) (case-of x) (not (tag-field (tp x) 'indeclinable))
         (any (lambda (e) (string-suffix? e g)) '("ite" "ian" "ean" "ites" "ians" "eans")) #t)))

(define (open-dative? env v i)
  "Whether the punctuation-delimited stretch of vector V around I has a
finite verb whose sense takes a dative object (a (dative ...) field: ὁράω
appear) and no dative word yet."
  (let* ((n (vector-length v))
         (start (let back ((k i)) (if (and (> k 0) (string-null? (u (vector-ref v (- k 1)) 'post))) (back (- k 1)) k)))
         (end (let fwd ((k i)) (if (and (< k (- n 1)) (string-null? (u (vector-ref v k) 'post))) (fwd (+ k 1)) (+ k 1))))
         (ws (map (lambda (k) (vector-ref v k)) (iota (- end start) start))))
    ;; (a recipient, (dative "to"): not a dative object like ἀκούω's "")
    (and (any (lambda (y) (and (finite? y) (equal? (field1 (unit-sense env y) 'dative) "to"))) ws)
         (not (any (lambda (y) (and (eqv? (case-of y) #\D) (or (nominal? y) (u y 'phrase)))) ws)))))

(define %saying '("λέγω" "λαλέω" "φημί"))

(define (mark-name-speech! env v)
  "Where Swete's capital opens direct speech though the word is a name (a
capital that also marks every name) or follows a preposition or article
(a capital common noun used as a name), in vector V (gsb/literal/README.md,
Clauses):
- εἰς Σκηνάς, τὸ Εἶδος τοῦ θεοῦ: a capital common noun after a preposition
  or article is a name, not speech;
- λέγων Συχὲμ ὁ υἱός μου: a capital right after a participle of saying opens
  speech;
- εἶπεν αὐτῇ ὁ ἄγγελος Κυρίου Ἁγάρ, Εἶπεν δὲ ὁ θεὸς τῷ Ἀβραὰμ Σάρα: a
  capital name after a verb of saying whose subject (a nominative) and
  addressee (a dative or πρός) both stand between opens speech, unless it
  follows a nominative common noun (ὁ θεὸς Ἰακώβ, its genitive);
- εἶπέν μοι Κύριος ὁ θεός, ᾧ ..., αὐτὸς ἐξαποστελεῖ: a capital nominative
  right after a verb of saying and its addressee, resumed after a comma by
  αὐτός before a finite verb, is a hanging nominative opening speech."
  (let ((n (vector-length v)))
    (define (at i) (and (>= i 0) (< i n) (vector-ref v i)))
    (define (prev-index i) (let back ((k (- i 1))) (if (and (at k) (apply lemma-in? (at k) %postpositive)) (back (- k 1)) k)))
    (define (speech! i) (vector-set! v i (u+ (at i) 'speech #t)))
    (define (saying-verb? y) (and y (finite? y) (apply lemma-in? y %saying)))
    (do ((i 1 (+ i 1))) ((>= i n))
      (let* ((x (at i)) (p (at (prev-index i))))
        (cond
         ;; καθ’ ὕπνον Ἰακὼβ Ἰακώβ: a name said twice is a call (before the
         ;; noun before it can make it its genitive)
         ((and (is? x "N") (not (case-of x)) (at (+ i 1)) (equal? (lemma x) (lemma (at (+ i 1)))) (string-null? (u x 'post)))
          (vector-set! v i (u+ x 'tp (cons '(case . #\V) (tp x)) 'speech #t))
          (vector-set! v (+ i 1) (u+ (at (+ i 1)) 'tp (cons '(case . #\V) (tp (at (+ i 1)))))))
         ((and (u x 'speech) (u x 'lower-cap) p (is? p "PREP" "T") (string-null? (u p 'post)))
          (vector-set! v i (u+ x 'speech #f 'keep-cap #t)))
         ;; (a preposition's or article's name is no speech: πρὸς Κάιν, τῷ Ἀβραάμ)
         ((or (u x 'speech) (not (u x 'cap)) (not (is? x "N")) (memv (case-of x) '(#\G #\D #\A #\V))
              (and p (is? p "PREP" "T")))
          #f)
         ((and p (participle? p) (lemma-in? p "λέγω") (string-null? (u p 'post)))
          (speech! i))
         (else
          ;; back to the verb of saying, inside one punctuation stretch
          (let back ((k (- i 1)) (nom? #f) (dat? #f) (only-objects? #t))
            (let ((y (at k)))
              (cond
               ;; (nor a name inside speech already open: Ἐγὼ Ἠσαύ)
               ((or (not y) (not (string-null? (u y 'post))) (u y 'speech)) #f)
               ((saying-verb? y)
                (let ((before-x (at (- i 1))))
                  (cond
                   ((and nom? dat? (not (and before-x (is? before-x "N") (case-of before-x) (not (eqv? (case-of before-x) #\G))
                                             (not (name-like? env before-x)))))
                    (speech! i))
                   ((and only-objects? dat? (eqv? (case-of x) #\N)
                         ;; resumed by αὐτός + finite verb after a comma, a relative between
                         (let fwd ((m (+ i 1)) (comma? #f) (rel? #f))
                           (let ((z (at m)))
                             (cond ((not z) #f)
                                   ((strong-stop? (u (at (- m 1)) 'post)) #f)
                                   ((and comma? rel? (lemma-in? z "αὐτός") (eqv? (case-of z) #\N) (finite? (at (+ m 1)))) #t)
                                   (else (fwd (+ m 1) (or comma? (string-contains (u (at (- m 1)) 'post) ",")) (or rel? (is? z "R"))))))))
                    (speech! i)))))
               ((finite? y) #f)
               (else (back (- k 1)
                           (or nom? (and (eqv? (case-of y) #\N) (or (nominal? y) (u y 'phrase))))
                           (or dat? (eqv? (case-of y) #\D) (lemma-in? y "πρός"))
                           (and only-objects? (is? y "P") (not (eqv? (case-of y) #\N))))))))))))))

(define (assign-roles env units)
  "Article roles, possessive and demonstrative pronouns, πᾶς every/all."
  (let* ((v (list->vector units)) (n (vector-length v)))
    (define (at i) (and (>= i 0) (< i n) (vector-ref v i)))
    (define (skip-post k step) (if (and (at k) (apply lemma-in? (at k) %postpositive)) (skip-post (+ k step) step) k))
    (mark-name-speech! env v)
    ;; An indeclinable name or numeral takes its article's case (τὸν Ἀδάμ,
    ;; οἱ δύο, τῷ δὲ Ἀδάμ) or its preposition's (ἐξ Ἐδέμ).
    (do ((i 1 (+ i 1))) ((>= i n))
      (let ((x (at i)) (p (at (skip-post (- i 1) -1))))
        (when (and (is? x "N" "A") (not (case-of x)) p (not (u x 'speech)))
          (cond ((and (is? x "A")
                      ;; a numeral takes its noun's case: ἐν ἓξ ἡμέραις, also
                      ;; through a compound numeral: ὀγδοήκοντα ἓξ ἐτῶν
                      (let ((noun (let next ((k (+ i 1)))
                                    (let ((y (at k)))
                                      (cond ((not y) #f)
                                            ((and (is? y "N") (case-of y)) y)
                                            ((or (numeral? y) (lemma-in? y "καί")) (next (+ k 1)))
                                            (else #f))))))
                        noun))
                 => (lambda (noun)
                      (vector-set! v i (u+ x 'tp (append (filter (lambda (kv) (memq (car kv) '(case number gender))) (tp noun)) (tp x))))))
                ((and (is? p "T") (case-of p))
                 (vector-set! v i (u+ x 'tp (append (filter (lambda (kv) (memq (car kv) '(case number gender))) (tp p)) (tp x)))))
                ;; περὶ Ῥαχὴλ τῆς θυγατρός σου, ὑπὸ Φαραὼ τοῦ βασιλέως, Λαβὰν
                ;; Ῥαχὴλ τῇ θυγατρὶ αὐτοῦ: after a preposition of several cases or
                ;; another name, a name takes the case of the person noun in
                ;; apposition after it (article + noun)
                ((and (is? x "N") (or (is? p "PREP") (caseless-name? p)) (string-null? (u x 'post))
                      (apposition-case env (at (+ i 1)) (at (+ i 2))))
                 => (lambda (c) (vector-set! v i (u+ x 'tp (cons (cons 'case c) (tp x))))))
                ((and (is? p "PREP") (assoc (lemma p) %prep-case))
                 => (lambda (pc) (vector-set! v i (u+ x 'tp (cons (cons 'case (cdr pc)) (tp x))))))
                ;; after a preposition of several cases (ἐπὶ Ἅβελ) it is at least
                ;; not a nominative
                ((is? p "PREP") (vector-set! v i (u+ x 'prep-obj #t)))
                ;; a name right after a noun is its genitive (τῷ οἴκῳ Ἰακώβ), except
                ;; after a title whose sense says (apposition) (ἡγεμὼν Θαιμάν "chief
                ;; Teman": the name is the title's case), and after a nominative
                ;; in a span whose verb takes a dative object and has none (Ὤφθη δὲ
                ;; ὁ θεὸς Ἰακώβ "God appeared to Jacob")
                ((and (is? x "N") (is? p "N") (not (tag-field (tp p) 'indeclinable)) (not (u p 'phrase))
                      (string-null? (u p 'post)))
                 (vector-set! v i (u+ x 'tp (cons (cons 'case (cond ((and (field (unit-sense env p) 'apposition) (case-of p) (eqv? (num-of p) #\S)) (case-of p))
                                                                     ((and (eqv? (case-of p) #\N) (open-dative? env v i)) #\D)
                                                                     (else #\G)))
                                                  (tp x)))))))))
    ;; εἶπεν αὐτῷ Ἀβραὰμ Ἀβραάμ: a name said twice is a call, a vocative that
    ;; opens speech
    (do ((i 0 (+ i 1))) ((>= i (- n 1)))
      (let ((x (at i)) (nx (at (+ i 1))))
        (when (and (is? x "N") (not (case-of x)) (equal? (lemma x) (lemma nx)) (string-null? (u x 'post)))
          (vector-set! v i (u+ x 'tp (cons '(case . #\V) (tp x)) 'speech (> i 0)))
          (vector-set! v (+ i 1) (u+ nx 'tp (cons '(case . #\V) (tp nx)))))))
    ;; ἐκλήθη τὸ ὄνομα αὐτῆς Σύγχυσις: a capital after ὄνομα or a verb of
    ;; naming is the name given, not direct speech
    (do ((i 1 (+ i 1))) ((>= i n))
      (let ((x (at i)))
        (when (and (u x 'speech) (u x 'lower-cap)
                   (let back ((k (- i 1)) (left 3))
                     (let ((y (at k)))
                       (cond ((or (not y) (= left 0) (lemma-in? y "λέγω") (not (string-null? (u y 'post)))) #f)
                             ((lemma-in? y "ὄνομα" "καλέω" "ὀνομάζω" "ἐπονομάζω" "ἐπικαλέω") #t)
                             (else (back (- k 1) (- left 1)))))))
          ;; it keeps its capital
          (vector-set! v i (u+ x 'speech #f 'keep-cap #t)))))
    ;; Δέσποτα Κύριε: a vocative after a vocative does not open speech
    (do ((i 1 (+ i 1))) ((>= i n))
      (let ((x (at i)))
        (when (and (u x 'speech) (eqv? (case-of x) #\V) (eqv? (case-of (at (- i 1))) #\V))
          (vector-set! v i (u+ x 'speech #f)))))
    ;; κύριος without the article (the divine name) takes a supplied "[the]":
    ;; a sense's (anarthrous "[the]").
    (do ((i 0 (+ i 1))) ((>= i n))
      (let* ((x (at i)) (s (and (is? x "N") (not (u x 'phrase)) (unit-sense env x))) (a (and s (field1 s 'anarthrous))))
        (when (and a (not (u x 'before)) (not (is? (at (skip-post (- i 1) -1)) "T"))
                   ;; (not for a human lord, κύριος in lower case)
                   (not (u x 'human-lord))
                   ;; a vocative takes no article: Κύριε "Lord"
                   (not (eqv? (case-of x) #\V)))
          (vector-set! v i (u+ x 'before a)))))
    ;; οὗ before a verb (or ἐάν, ἄν) is the adverb "where": τὸν γνόφον οὗ ἦν ὁ θεός.
    (do ((i 0 (+ i 1))) ((>= i (- n 1)))
      (let ((x (at i)) (nx (at (+ i 1))))
        (when (and (lemma-in? x "ὅς") (equal? (form-key (u x 'greek)) "οὗ") (not (u x 'sense))
                   (or (finite? nx) (lemma-in? nx "ἐάν" "ἄν")) (sense-of env "οὗ" 'where)
                   ;; after a genitive noun it is the attracted relative (τοῦ ξύλου οὗ)
                   (not (and (at (- i 1)) (is? (at (- i 1)) "N") (eqv? (case-of (at (- i 1))) #\G))))
          (vector-set! v i (u+ x 'lemma "οὗ" 'tag "ADV" 'tp (parse-tag "ADV") 'sense 'where
                               'refs (list (list (u x 'n) 'where "οὗ")))))))
    (do ((i 0 (+ i 1))) ((= i n))
      (let ((x (at i)) (p (at (- i 1))) (nx (at (skip-post (+ i 1) 1))))
        (cond
         ((or (u x 'phrase) (u x 'absorbed-by-pre)) #t)
         ((is? x "T")
          (vector-set! v i
            (u+ x 'role
                (cond ((or (infinitive? nx) (and (lemma-in? nx "μή") (infinitive? (at (+ i 2))))
                           ;; πρὸ τοῦ σε εἰσελθεῖν: the subject between
                           (and (is? nx "P") (eqv? (case-of nx) #\A) (infinitive? (at (+ i 2)))))
                       'infinitive)
                      ;; ὁ δέ, οἱ δέ: the article as a pronoun, "but he".
                      ((and (lemma-in? (at (+ i 1)) "δέ" "μέν") (not (nominal? (at (+ i 2))))
                            (sense-of env "ὁ" 'pronoun))
                       'pronoun)
                      ;; The article before a name is unrendered (τὸν Ἀβραάμ, Ἐφρὼν
                      ;; τοῦ Σάαρ "Ephron of Zohar"), but before the name of a people
                      ;; it is "the": ὁ Χαναναῖος "the Canaanite", Ἐφρὼν ὁ Χετταῖος
                      ;; "Ephron the Hittite"
                      ((and nx (name-like? env nx) (not (gentilic? env nx))
                            ;; Κύριε ὁ θεός: after a vocative, "the God"
                            (not (and p (eqv? (case-of p) #\V))))
                       'unrendered)
                      ;; (also past the noun's possessive: ὁ πατὴρ ὑμῶν ὁ
                      ;; πρεσβύτερος "your older father")
                      ((and p (let ((p (if (and (eq? (u p 'role) 'possessive) (string-null? (u p 'post)) (at (- i 2))) (at (- i 2)) p)))
                                (and (or (is? p "N") (and (is? p "A") (not (lemma-in? p "πᾶς"))) (participle? p) (u p 'phrase))
                                     (agree? p x)))
                            ;; τοῦ Νῶε, τοῦ δευτέρου μηνός: an adjective with its own
                            ;; noun after it starts a new phrase
                            (not (let ((nn (at (+ (skip-post (+ i 1) 1) 1))))
                                   (and nn (is? nx "A") (is? nn "N") (not (name-like? env nn)) (agree? nx nn))))
                            (or (is? nx "A" "PREP" "ADV") (participle? nx)
                                ;; τῶν κτηνῶν τῶν μὴ καθαρῶν
                                (and (lemma-in? nx "μή" "οὐ") (is? (at (+ i 2)) "A"))))
                       'attributive)
                      ((and (participle? nx) (not (and (at (+ i 2)) (is? (at (+ i 2)) "N") (agree? nx (at (+ i 2))))))
                       'the-one)
                      ;; τὰ ἐν αὐτοῖς: "the [things] in them"
                      ((is? nx "PREP") 'the-one)
                      ;; τῆς ἐμῆς φωνῆς "my voice": the possessive adjective takes
                      ;; the article's place
                      ((and nx (string? (u nx 'tag)) (string-prefix? "S-" (u nx 'tag))) 'absorbed)
                      ;; τὰ αὐτοῦ, πάντων τῶν αὐτοῦ: "the [things] of him"
                      ((and nx (eqv? (case-of nx) #\G) (is? nx "P" "T" "N")
                            ;; (a genitive article only after πᾶς: πάντων τῶν αὐτοῦ)
                            (or (not (eqv? (case-of x) #\G)) (and p (lemma-in? p "πᾶς") (agree? p x)))
                            ;; (no noun of its own follows: τὸν τοῦ θεοῦ λόγον is not)
                            (not (any (lambda (k) (let ((nn (at k))) (and nn (is? nn "N" "A") (agree? x nn))))
                                      (iota 5 (+ i 1)))))
                       'the-one)
                      (else 'the)))))
         ((and (is? x "P") (eqv? (case-of x) #\G) p (or (is? p "N") (and (u p 'phrase) (not (u p 'phrase-prep)))))
          (vector-set! v i (u+ x 'role 'possessive)))
         ;; A genitive pronoun before article + noun is possessive too
         ;; (ὑμῶν οἱ ὀφθαλμοί, "your eyes"); its article is absorbed.
         ((and (is? x "P") (eqv? (case-of x) #\G) (is? nx "T") (at (+ i 2)) (is? (at (+ i 2)) "N") (not (is? p "PREP"))
               (string-null? (u x 'post))   ; ἄκουσόν μου. τὸν ἀγρόν: not across punctuation
               ;; ἐπήκουσεν αὐτοῦ ὁ θεός: the object of a verb taking the genitive,
               ;; before its subject (but ἄκουσόν μου τῆς φωνῆς "hear my voice")
               (not (let ((v (at (skip-post (- i 1) -1))))
                      (and v (is? v "V") (field (unit-sense env v) 'genitive) (eqv? (case-of nx) #\N)))))
          (vector-set! v i (u+ x 'role 'possessive 'moved #t))
          (vector-set! v (+ i 1) (u+ nx 'role 'absorbed 'absorbed-by-pre #t)))
         ((and (is? x "P") (eqv? (case-of x) #\G) (is? nx "N") (not (is? p "N" "PREP")))
          (vector-set! v i (u+ x 'role 'possessive 'moved #t)))
         ;; ἐάν after a relative is "ever" (ὃ ἐάν), otherwise "if".
         ((and (lemma-in? x "ἐάν") (not (u x 'sense)) (not (is? p "R")) (not (lemma-in? p "οὗ")) (sense-of env "ἐάν" 'if))
          (vector-set! v i (set-sense x 'if)))
         ((and (lemma-in? x "τέ") (not (u x 'sense)))
          (vector-set! v i (set-sense x (if (any (lambda (k) (lemma-in? (at k) "καί")) (iota (max 0 (- n i 1)) (+ i 1))) 'both 'and))))
         ((and (is? x "D") p (is? p "N") (agree? p x)
               (let ((a (if (numeral? (at (- i 2))) (at (- i 3)) (at (- i 2)))))
                 (and a (is? a "T") (agree? a p)))
               ;; εἶπεν δὲ ὁ παῖς Οὗτός ἐστιν: a demonstrative opening speech is not the noun's
               (not (u x 'speech)) (string-null? (u p 'post)))
          (vector-set! v i (u+ x 'role 'post-demonstrative)))
         ;; A noun can choose the sense of the preposition before it:
         ;; (with-preposition "εἰς" for) on σημεῖον gives εἰς σημεῖα "for signs".
         ((and (is? x "PREP") (not (u x 'sense))
               (let* ((noun (find (lambda (y) (not (is? y "T" "A"))) (filter identity (map at (iota 3 (+ i 1))))))
                      (f (and noun (field (unit-sense env noun) 'with-preposition))))
                 ;; only for its own preposition (ἡμέρα's ἐν does not make μετὰ
                 ;; τὰς ἑπτὰ ἡμέρας "with")
                 (and (pair? f) (equal? (car f) (lemma x)) f)))
          => (match-lambda
               ((prep name) (vector-set! v i (set-sense x name)))
               (_ #f)))
         ;; A preposition sense may name the case it takes: μετά + accusative "after".
         ((and (is? x "PREP") (not (u x 'sense))
               (let* ((obj (let next ((k (+ i 1)) (left 6))
                             ;; past indeclinable numerals: μετὰ πεντήκοντα καὶ ἑκατὸν ἡμέρας
                             (let ((y (at k)))
                               (cond ((or (not y) (= left 0)) #f)
                                     ((case-of y) y)
                                     ((or (numeral? y) (lemma-in? y "καί") (= k (+ i 1))) (next (+ k 1) (- left 1)))
                                     (else #f)))))
                      (senses (hash-ref (env-senses env) (lemma x) '())))
                 (and obj (find (lambda (s) (equal? (field1 s 'object-case) (string (case-of obj)))) senses))))
          => (lambda (s) (vector-set! v i (set-sense x (car s)))))
         ;; ἀνά outside ἀνὰ μέσον is distributive: ἀνὰ δραχμήν "each drachma"
         ((and (lemma-in? x "ἀνά") (not (u x 'sense)) (not (u x 'phrase)) (sense-of env "ἀνά" 'each))
          (vector-set! v i (set-sense x 'each)))
         ;; δύο δύο, ἑπτὰ ἑπτά: "two [by] two"
         ((and (numeral? x) nx (equal? (lemma x) (lemma nx)) (not (u x 'after)) (string-null? (u x 'post)))
          (vector-set! v i (u+ x 'after "[by]")))
         ;; ὅπως ἄν, ἵνα ἄν: "in order that", the ἄν unrendered
         ((and (lemma-in? x "ἄν") (not (u x 'sense)) (lemma-in? p "ὅπως" "ἵνα") (sense-of env "ἄν" 'unrendered))
          (vector-set! v i (set-sense x 'unrendered)))
         ((and (lemma-in? x "πᾶς") (not (ref-sense* (car (u x 'refs)))))
          (vector-set! v i (set-sense x (if (and (eqv? (num-of x) #\S) (not (is? nx "T"))) 'every 'all)))))))
    ;; τὰ σά, τῶν σῶν: a possessive adjective with no noun, "your [things]"
    (do ((i 1 (+ i 1))) ((>= i n))
      (let ((x (at i)) (nx (at (+ i 1))))
        (when (and (string? (u x 'tag)) (string-prefix? "S-" (u x 'tag)) (is? (at (- i 1)) "T") (not (u x 'after))
                   (not (and nx (is? nx "N") (agree? x nx))))
          (vector-set! v i (u+ x 'after (string-append "[" (if (eqv? (gen-of x) #\N) "thing" "one") (if (eqv? (num-of x) #\P) "s" "") "]"))))))
    ;; ἄν with a past indicative is unreal, "would have" (ἐξαπέστειλα ἄν σε
    ;; "I would have sent you out"), with an optative potential, "would" (πῶς
    ;; ἂν κλέψαιμεν "how would we steal"); ἄν itself is unrendered. With a
    ;; subjunctive it stays "ever" (ὃς ἄν).
    (do ((i 0 (+ i 1))) ((>= i n))
      (let ((x (at i)))
        (when (and (lemma-in? x "ἄν") (not (u x 'sense)) (sense-of env "ἄν" 'unrendered))
          (let* ((stretch (let ((start (let back ((k i)) (if (and (> k 0) (string-null? (u (at (- k 1)) 'post))) (back (- k 1)) k)))
                                (end (let fwd ((k i)) (if (and (< k (- n 1)) (string-null? (u (at k) 'post))) (fwd (+ k 1)) (+ k 1)))))
                            (iota (- end start) start)))
                 ;; the nearest finite verb, after it first
                 (k (or (find (lambda (k) (and (> k i) (finite? (at k)))) stretch)
                        (find (lambda (k) (and (< k i) (finite? (at k)))) (reverse stretch))))
                 (y (and k (at k))))
            (when (and y (or (eqv? (mood y) #\O)
                             (and (eqv? (mood y) #\I) (memv (tag-field (tp y) 'tense) '(#\A #\I #\L))
                                  ;; (after a subordinator it is iterative, "ever": ὡς ἂν
                                  ;; εἰσεπορεύοντο "as ever ... were entering")
                                  (let ((p (let back ((m (- i 1))) (let ((z (at m))) (if (and z (apply lemma-in? z %postpositive)) (back (- m 1)) z)))))
                                    (not (and p (or (is? p "R") (apply lemma-in? p %mh-subordinators))))))))
              (vector-set! v i (set-sense x 'unrendered))
              (vector-set! v k (u+ y 'would #t)))))))
    ;; Demonstrative before article + noun: the article is absorbed (not
    ;; before a participle: οὗτος ὁ κυκλῶν "this the [one] encircling").
    (do ((i 0 (+ i 1))) ((>= i (- n 1)) (vector->list v))
      (let ((x (at i)) (nx (at (+ i 1))))
        (when (and (is? x "D") (is? nx "T") (agree? x nx) (is? (at (+ i 2)) "N" "A"))
          (vector-set! v (+ i 1) (u+ nx 'role 'absorbed)))))))

(define (np-start? x p)
  "Whether X begins a noun phrase (P, the word before it, is not in it)."
  (cond ((is? x "T") (not (or (eq? (u x 'role) 'attributive)
                              (and p (or (lemma-in? p "πᾶς") (is? p "D")) (agree? p x)))))
        ((not p) #t)
        ((is? x "N") (not (and (or (is? p "T" "A" "D" "R") (participle? p)) (agree? p x))))
        ((is? x "A" "D") (not (and (or (is? p "T" "A" "N" "D")) (agree? p x))))
        ((participle? x) (not (and (is? p "T" "N") (agree? p x))))
        (else #t)))

(define (assign-helpers env units)
  "The English preposition a genitive or dative noun phrase needs (\"of\",
\"to\"), on the phrase's first word, in Greek order."
  (let loop ((us units) (prev '()) (last-helper '()) (acc '()))
    (if (null? us)
        (reverse acc)
        (let* ((x (car us))
               (c (case-of x))
               ;; The word before, looking past δέ/γάρ (ἀπὸ δὲ τοῦ ξύλου).
               (p (find (lambda (y) (not (or (apply lemma-in? y "ἄν" %postpositive)
                                             ;; τῶν μὴ καθαρῶν: the adjective is still the article's
                                             (and (lemma-in? y "μή" "οὐ") (is? x "A")))))
                        prev)))
          (if (not (and (memv c '(#\G #\D)) (or (nominal? x) (u x 'phrase)) (not (u x 'phrase-prep))
                        ;; a genitive absolute takes no "of": "he being seated"
                        (not (u x 'gabs)) (not (u x 'gabs-start))
                        (not (eq? (u x 'role) 'possessive)) (np-start? x p)
                        ;; ταῖς ἑαυτοῦ γυναιξίν: the article two back starts the phrase
                        (not (and p (is? p "F" "P") (eqv? (case-of p) #\G) (is? x "N")
                                  (let ((pp (find (lambda (y) (not (eq? y p))) (cdr (member p prev)))))
                                    (and pp (is? pp "T") (agree? pp x)))))))
              (loop (cdr us) (cons x prev) last-helper (cons x acc))
              (let* ((gov (find (lambda (y) (not (or (and (eqv? (case-of y) #\N) (not (participle? y))) (eq? (u y 'role) 'possessive)
                                                     ;; (an indeclinable name: ἀναβλέψας Ἀβραὰμ τοῖς ὀφθαλμοῖς)
                                                     (caseless-name? y)
                                                     (apply lemma-in? y %postpositive))))
                                prev))
                     (key (if (eqv? c #\G) 'genitive 'dative))
                     ;; The phrase's own helper comes from its noun (τῇ ἡμέρᾳ "on").
                     (head (let ((phrase (take-while (lambda (y) (or (is? y "T" "A" "D" "R" "N") (apply lemma-in? y "ἄν" %postpositive)))
                                                     (take us (min 4 (length us))))))
                             ;; with no noun, its adjective: τῇ πρώτῃ τοῦ μηνός "on the first"
                             (or (find (lambda (y) (and (is? y "N") (memv (case-of y) (list c #f)))) phrase)
                                 (find (lambda (y) (and (is? y "A") (eqv? (case-of y) c))) phrase)
                                 x)))
                     (own (field1 (unit-sense env head) key))
                     (gov-field (or (and p (is? p "A") (field1 (unit-sense env p) key))
                                    (and gov (is? gov "V") (field1 (unit-sense env gov) key))))
                     (before-kai (and p (lemma-in? p "καί" "ἤ")
                                      (find (lambda (y) (not (eq? (u y 'role) 'possessive))) (cdr (member p prev))))))
                (let-values (((h sticky?)
                              (cond
                               ;; after a preposition, or an adverb used as one (ἐπάνω τῆς ἀβύσσου)
                               ((and p (or (is? p "PREP") (and (is? p "ADV") (assoc (lemma p) %prep-case)))) (values "" #t))
                               ;; an apposition shares its name's helper: ἀπὸ Ἀβραὰμ
                               ;; τοῦ παιδός μου "from Abraham my servant", Σάρᾳ τῇ
                               ;; γυναικὶ αὐτοῦ "to Sarai his woman"
                               ((and p (name-like? env p) (not (lemma-in? p "θεός")) (eqv? (case-of p) c)
                                     (let ((noun (if (is? x "T") (find (lambda (y) (not (is? y "T" "A"))) (take (cdr us) (min 2 (length (cdr us))))) x)))
                                       ;; (with its article also a gentilic: Ἐφρὼν τοῦ Χετταίου
                                       ;; "Ephron the Hittite")
                                       (and noun (is? noun "N") (or (not (name-like? env noun)) (and (is? x "T") (gentilic? env noun)))
                                            (person-noun? env noun))))
                                (values "" #f))
                               ;; "of the sea and the birds": a phrase joined by
                               ;; καί to one in the same case shares its helper.
                               ((and before-kai (eqv? (case-of before-kai) c) (assv c last-helper))
                                => (lambda (p) (values (cdr p) #t)))
                               (gov-field (values gov-field #t))
                               (own (values own #t))
                               ;; a relative in its antecedent's case is attracted
                               ;; (τῶν ἔργων ... ὧν ἐποίησεν): "which", not "of which"
                               ((is? x "R")
                                ;; (a substantival adjective too: ἀπὸ πασῶν ὧν)
                                (let ((ante (find (lambda (y) (is? y "N" "A")) prev)))
                                  (values (if (and (eqv? c #\G) (not (and ante (eqv? (case-of ante) c)))) "of" "") #f)))
                               ((eqv? c #\G) (values "of" (not (and gov (or (is? gov "N") (u gov 'phrase))))))
                               (else (values "to" #t)))))
                  (let* ((articular-inf (and (is? x "T") (eq? (u x 'role) 'infinitive)))
                         (h (if (and articular-inf (string=? h "of") (not (and gov (is? gov "N")))) "" h)))
                    (loop (cdr us) (cons x prev)
                          (if sticky? (cons (cons c h) (alist-delete c last-helper)) last-helper)
                          (cons (u+ x 'helper h
                                    'gerund (and articular-inf (or (not (string-null? h)) (and gov (is? gov "PREP")))))
                                acc))))))))))

;;; Verse context (gsb/AGENTS.md rule 16a): no pronoun or relative is
;;; resolved from a nearby noun's meaning, except "who" for a relative whose
;;; agreeing antecedent is a person.

(define (person-noun? env y)
  (let ((s (unit-sense env y)))
    (and s (or (assq 'person (cdr s))
               ;; a proper name (capital gloss): not ὄνομα, whose sense is also called name
               (and (eq? (car s) 'name) (string-index (gloss1 s) char-upper-case?))
               (lemma-in? y "θεός"))
         #t)))

(define (strong-stop? post)
  (and (or (string-contains post "·") (string-contains post ".") (string-contains post ";")) #t))

(define (assign-verse-context env units)
  "Mark a third person verb joined by καί to an earlier verb of the same
sentence ('kai-joined: it gets no pronoun, as the Greek has none), and a
relative pronoun whose nearest agreeing noun is a person ('person-ante)."
  (let loop ((us units) (prev '()) (verb-before? #f) (acc '()))
    (if (null? us)
        (reverse acc)
        (let* ((x (car us))
               ;; καὶ οὐκ ἐτεκνοποίει: past a negation
               (kai (and (pair? prev)
                         (if (and (lemma-in? (car prev) "οὐ" "μή") (pair? (cdr prev))) (cadr prev) (car prev))))
               (x (cond
                   ((and (finite? x) (eqv? (or (tag-field (tp x) 'person) #\3) #\3) verb-before?
                         kai (lemma-in? kai "καί") (string-null? (u kai 'post))
                         ;; joined only to a verb of the same person and number
                         ;; (ἠμβλύνθησαν ... καὶ ἐκάλεσεν is not)
                         (eqv? (tag-field (tp verb-before?) 'number) (tag-field (tp x) 'number))
                         (eqv? (or (tag-field (tp verb-before?) 'person) #\3) #\3))
                    (u+ x 'kai-joined #t))
                   ;; The relative's antecedent is the nearest noun; "who" only
                   ;; when that noun agrees and is a person.
                   ;; An indeclinable name (no case) agrees only through its
                   ;; article; a relative followed by its own noun (ᾗ ἡμέρᾳ) is
                   ;; adjectival and looks at no antecedent.
                   ((is? x "R")
                    (let ((a (find (lambda (y) (and (or (is? y "N") (u y 'phrase)) (case-of y))) prev))
                          (own-noun? (and (pair? (cdr us)) (is? (cadr us) "N") (agree? x (cadr us)))))
                      (if (and a (not own-noun?) (person-noun? env a)
                               (eqv? (num-of a) (num-of x))
                               (memv (gen-of a) (list (gen-of x) #f)))
                          (u+ x 'person-ante #t)
                          x)))
                   (else x))))
          (loop (cdr us) (cons x prev)
                ;; the last finite verb of the sentence
                (and (not (strong-stop? (u x 'post))) (if (finite? x) x verb-before?))
                (cons x acc))))))

(define (resolve-pronouns env units prev-units)
  "A third person singular oblique pronoun (αὐτοῦ, αὐτήν, ἑαυτῷ ...) takes
'ante: 'person when its nearest agreeing noun is a person, 'thing when it is
not (Greek gender on a thing is grammatical: αὐτήν for ἡμέρα is \"it\"). The
nearest agreeing noun is looked for earlier in the verse, then in the verse
before (PREV-UNITS); with none, the pronoun keeps its open form (\"his/its\")
or its plain gender. The nominative αὐτός (\"he\") is not resolved.
ponytail: nearest agreeing noun, not syntax; a wrong pick is a word override
with the open form (english \"his/its\")."
  ;; A noun with its own third person possessive (τὸν παῖδα αὐτοῦ) is the
  ;; thing owned, not the owner the next αὐτοῦ points to: never an
  ;; antecedent. (τοῦ πλησίον σου still is one.)
  (define (possessed-set us)
    (let ((h (make-hash-table)))
      (let loop ((us us))
        (when (and (pair? us) (pair? (cdr us)))
          (when (and (eq? (u (cadr us) 'role) 'possessive) (lemma-in? (cadr us) "αὐτός" "ἑαυτοῦ"))
            (hashq-set! h (car us) #t))
          (loop (cdr us))))
      ;; τὸ ὄνομα τοῦ υἱοῦ αὐτοῦ: the noun a genitive owned noun depends on is
      ;; not the owner either
      (let loop ((us (reverse us)))
        (when (pair? us)
          (let ((y (car us)))
            (when (and (hashq-ref h y) (eqv? (case-of y) #\G))
              (let ((head (find (lambda (z) (not (is? z "T"))) (cdr us))))
                ;; (not a name it is in apposition to: ἀντὶ Ἰσαὰκ τοῦ υἱοῦ αὐτοῦ)
                (when (and head (is? head "N") (not (person-noun? env head))) (hashq-set! h head #t)))))
          (loop (cdr us))))
      h))
  (define owned (possessed-set (append prev-units units)))
  (let loop ((us units) (prev '()) (acc '()))
    (if (null? us)
        (reverse acc)
        (let* ((x (car us))
               (x (if (and (lemma-in? x "αὐτός" "ἑαυτοῦ") (eqv? (or (tag-field (tp x) 'person) #\3) #\3)
                           (eqv? (num-of x) #\S) (case-of x) (not (eqv? (case-of x) #\N)))
                      (let* ((gs (if (mn-ambiguous? x) '(#\M #\N) (list (gen-of x))))
                             ;; a reflexive points to its clause's subject, which may
                             ;; follow it: ἔλαβεν ἑαυτῷ Λάμεχ
                             (pool (append prev
                                           (if (lemma-in? x "ἑαυτοῦ")
                                               (filter (lambda (y) (memv (case-of y) '(#\N #f))) (cdr us))
                                               '())
                                           (reverse prev-units)))
                             (a (find (lambda (y)
                                        (and (or (is? y "N") (u y 'phrase)) (not (hashq-ref owned y))
                                             (memv (num-of* y) '(#\S))
                                             (memv (or (gen-of y) (and (person-noun? env y) #\M)) gs)))
                                      pool)))
                        (if a (u+ x 'ante (if (person-noun? env a) 'person 'thing)) x))
                      x)))
          (loop (cdr us) (cons x prev) (cons x acc))))))

(define (clauses span)
  "SPAN cut before καί + finite verb and before the start of direct speech."
  (let loop ((us span) (cur '()) (acc '()))
    (match us
      (() (reverse (if (null? cur) acc (cons (reverse cur) acc))))
      ((x . rest)
       (if (and (pair? cur)
                (or (u x 'speech)
                    (and (lemma-in? x "καί") (pair? rest) (finite? (car rest)))))
           (loop rest (list x) (cons (reverse cur) acc))
           (loop rest (cons x cur) acc))))))

(define (num-of* y) (or (num-of y) (and (is? y "N") #\S)))

(define (mark-gerunds env units)
  "An articular infinitive after a noun or preposition is a gerund (\"of
knowing\", \"after begetting\"); after a preposition, an accusative pronoun
right after it is its subject when the infinitive is εἶναι or intransitive,
or another accusative follows (its object): μετὰ τὸ γεννῆσαι αὐτὸν τὸν Σήθ
\"after his begetting Seth\", ἐν τῷ εἶναι αὐτούς \"in their being\"."
  (let* ((v (list->vector units)) (n (vector-length v)))
    (define (at i) (and (>= i 0) (< i n) (vector-ref v i)))
    (define (acc-after? k)
      ;; an accusative noun phrase (the infinitive's object) starts at K
      (let ((y (at k))) (and y (or (eqv? (case-of y) #\A) (caseless-name? y)) (or (nominal? y) (u y 'phrase)) (not (is? y "R")))))
    (do ((i 0 (+ i 1))) ((>= i n) (vector->list v))
      (let ((x (at i)))
        (when (and (is? x "T") (eq? (u x 'role) 'infinitive))
          (let* ((pre-subj (and (is? (at (+ i 1)) "P") (eqv? (case-of (at (+ i 1))) #\A) (infinitive? (at (+ i 2)))))
                 (k (cond (pre-subj (+ i 2)) ((lemma-in? (at (+ i 1)) "μή") (+ i 2)) (else (+ i 1))))
                 (inf (at k))
                 ;; (past δέ: ἐν δὲ τῷ ἀκοῦσαι αὐτόν)
                 (before (let back ((m (- i 1))) (let ((y (at m))) (if (and y (apply lemma-in? y %postpositive)) (back (- m 1)) y))))
                 (after-prep (and before (or (is? before "PREP") (assoc (lemma before) %prep-case)) #t))
                 (sense (unit-sense env inf))
                 (intrans (or (lemma-in? inf "εἰμί") (and sense (assq 'intransitive (cdr sense)))
                              ;; a true passive (not a passive deponent, V-AON: μνησθῆναι)
                              (and inf (eqv? (tag-field (tp inf) 'voice) #\P) (not (equal? (field1 sense 'voice) 'active))))))
            ;; πρὸ τοῦ σε εἰσελθεῖν: the subject before the infinitive
            (when pre-subj (vector-set! v (+ i 1) (u+ (at (+ i 1)) 'role 'inf-subject)))
            (when (infinitive? inf)
              (let ((s (at (+ k 1))) (gerund? (or (u x 'gerund) after-prep pre-subj)))
                (define (subject-found!)
                  ;; τοῦ ζῆσαι τὴν ψυχήν μου: with a subject the infinitive is a
                  ;; possessive gerund too, "of my soul's living"
                  (unless gerund?
                    (vector-set! v k (u+ (at k) 'gerund #t))
                    (when (and (eqv? (case-of x) #\G) (string-null? (u x 'helper)))
                      (vector-set! v i (u+ (at i) 'helper "of")))))
                (when gerund? (vector-set! v k (u+ inf 'gerund #t)))
                (cond
                 (pre-subj #t)
                 ;; μετὰ τὸ γεννῆσαι αὐτὸν τὸν Σήθ, ἐν τῷ κινῆσαι αὐτούς: an
                 ;; accusative pronoun is the subject when the infinitive is
                 ;; intransitive, or (after a preposition) another accusative, its
                 ;; object, follows; else it is the object (ἐν τῷ εὐλογεῖν αὐτόν
                 ;; "in blessing him"; τοῦ μὴ ἀνελεῖν αὐτὸν πάντα τὸν εὑρίσκοντα).
                 ((and s (is? s "P") (eqv? (case-of s) #\A) (or intrans (and after-prep (acc-after? (+ k 2)))))
                  (vector-set! v (+ k 1) (u+ s 'role 'inf-subject))
                  (subject-found!))
                 ;; ἕως τοῦ ἀποστεῖλαί σε "until your sending", ἐν τῷ τίκτειν αὐτήν
                 ;; "in her bearing", αἱ ἡμέραι τοῦ τεκεῖν αὐτήν "the days of her
                 ;; bearing": after a preposition or a noun, the one pronoun of a
                 ;; transitive infinitive is its subject (the gerund names a time
                 ;; or a thing by its doer); bare τοῦ + infinitive after a verb is a
                 ;; purpose, its pronoun the object (τοῦ ποιῆσαι αὐτό "to make it").
                 ;; Unless a finite verb of the same lemma comes before in the verse:
                 ;; then the infinitive restates it and the pronoun is its object
                 ;; (εὐλόγησεν Ἰσαὰκ τὸν Ἰακὼβ ... ἐν τῷ εὐλογεῖν αὐτόν "in blessing
                 ;; him"). A rule, not syntax: `check` warns inf-subject-by-rule.
                 ((and s (is? s "P") (eqv? (case-of s) #\A) (not (eq? (u s 'role) 'possessive))
                       ;; (one accusative only: τοῦ μὴ ἀνελεῖν αὐτὸν πάντα τὸν
                       ;; εὑρίσκοντα has its subject after; nor after a person, the
                       ;; main verb's subject: ταχυνεῖ ὁ θεὸς τοῦ ποιῆσαι αὐτό)
                       (not (acc-after? (+ k 2)))
                       ;; (a preposition of time: ἕνεκεν τοῦ πειράσαι ὑμᾶς is a
                       ;; purpose, "on account of testing you")
                       (or (lemma-in? before "ἐν" "ἕως" "πρό" "μετά" "ἅμα" "μέχρι")
                           (and (is? (at (- i 1)) "N") (not (person-noun? env (at (- i 1))))))
                       ;; (a third person pronoun and narrative verb: Ἐγώ σοι
                       ;; ἀποστέλλω ... ἕως τοῦ ἀποστεῖλαί σε is "your sending")
                       (not (and (lemma-in? s "αὐτός")
                                 (any (lambda (m) (let ((y (at m))) (and (finite? y) (equal? (lemma y) (lemma inf))
                                                                         (eqv? (tag-field (tp y) 'person) #\3))))
                                      (iota i)))))
                  (vector-set! v (+ k 1) (u+ s 'role 'inf-subject 'inf-subject-by-rule #t))
                  (subject-found!))
                 ;; A noun subject: μετὰ τὸ διαχωρισθῆναι τὸν Λώτ, ἐν τῷ ἐκτρῖψαι
                 ;; Κύριον πάσας τὰς πόλεις, μετὰ τὸ γηρᾶσαι Ἰσαάκ: an accusative
                 ;; (or indeclinable name) phrase after the infinitive is its
                 ;; subject when the infinitive is intransitive or passive, takes
                 ;; a genitive object, an object follows, or it is a name.
                 ((and s (not (is? s "P" "R")) (or (eqv? (case-of s) #\A) (caseless-name? s))
                       (scan-np (vector->list v) (+ k 1) #f #:want #\A #:env env))
                  => (lambda (np)
                       (when (pair? np)
                         (let* ((end (first np))
                                (gen-obj (and (field sense 'genitive) (at end) (eqv? (case-of (at end)) #\G)))
                                ;; φείσασθαι Κύριον αὐτοῦ: with a verb taking a
                                ;; genitive, αὐτοῦ is the object, not "his Lord"
                                (poss-obj (and (field sense 'genitive) (let ((y (at (- end 1))))
                                                                         (and (is? y "P") (eq? (u y 'role) 'possessive) (> (- end 1) (+ k 1))))))
                                (end (if poss-obj (- end 1) end)))
                           (when (or intrans gen-obj poss-obj (acc-after? end) (caseless-name? (third np)))
                             (when poss-obj (vector-set! v end (u+ (at end) 'role #f)))
                             (for-each (lambda (m) (vector-set! v m (u+ (at m) 'inf-np #t))) (iota (- end k 1) (+ k 1)))
                             (subject-found!)))))))))))))))

(define (mark-genitive-absolutes env units)
  "A genitive absolute: an anarthrous genitive participle with a genitive
subject agreeing with it, not governed by a preposition, an article, a noun
or a verb taking the genitive: καθημένου αὐτοῦ \"he being seated\", ἔτι
ζῶντος αὐτοῦ \"he still living\". The participle ('gabs) and its subject
('gabs-subj) take no \"of\"; the subject goes before the participle in
the nominative (np-internal-moves)."
  (let* ((v (list->vector units)) (n (vector-length v)))
    (define (at i) (and (>= i 0) (< i n) (vector-ref v i)))
    (do ((i 0 (+ i 1))) ((>= i n) (vector->list v))
      (let* ((x (at i))
             (pk (let back ((k (- i 1))) (let ((y (at k))) (if (and y (or (lemma-in? y "ἔτι") (apply lemma-in? y %postpositive))) (back (- k 1)) k))))
             (p (at pk))
             (s (at (+ i 1))))
        (when (and (participle? x) (eqv? (case-of x) #\G)
                   (not (and p (or (is? p "PREP" "T")
                                   ;; (an attributive participle follows its noun directly)
                                   (and (= pk (- i 1)) (string-null? (u p 'post))
                                        (eqv? (case-of p) #\G) (or (nominal? p) (u p 'phrase)))
                                   (and (is? p "V" "A") (field (unit-sense env p) 'genitive)))))
                   s (eqv? (case-of s) #\G) (is? s "P" "T" "N") (not (eq? (u s 'role) 'possessive))
                   (eqv? (num-of s) (num-of x)) (memv (gen-of s) (list (gen-of x) #f)))
          (let ((np (scan-np (vector->list v) (+ i 1) #t #:want #\G #:env env)))
            (when (pair? np)
              (vector-set! v i (u+ x 'gabs #t))
              (for-each (lambda (m) (vector-set! v m (u+ (at m) 'gabs-subj #t (if (memv m (fourth np)) 'gabs-start 'gabs-in) #t)))
                        (iota (- (first np) i 1) (+ i 1))))))))))

;;; μή (gsb/literal/README.md, "Negation"): a question expecting "no", a
;;; prohibition, a fear ("lest") or a plain "not", decided in Greek order.

(define %mh-subordinators
  '("ἵνα" "ὅπως" "ἐάν" "εἰ" "ὅταν" "ὅτι" "ἕως" "ὥστε" "διότι" "ὡς" "ἄν" "ὅς" "ὅστις" "πρίν" "ὅτε" "ἡνίκα"))

(define (mark-mh env units)
  "μή opening a sentence that ends in a question mark (no subordinator before
it) marks a yes/no question: μή is unrendered ('yn-q, sense question) and
its finite verb gets 'yn-question (\"Is utterance impossible beside God?\").
Otherwise, outside a subordinate clause: μή ποτε and μή + first or third
person subjunctive are \"lest\"; μή (or μηδέ) + second person subjunctive is a
prohibition ('prohibit: no subject pronoun, \"do not pass by\")."
  (let* ((v (list->vector units)) (n (vector-length v)))
    (define (at i) (and (>= i 0) (< i n) (vector-ref v i)))
    (define (prev-word i)
      ;; the word before I, past postpositives; #f at a sentence start
      (let loop ((k (- i 1)))
        (let ((y (at k)))
          (cond ((not y) #f)
                ((strong-stop? (u y 'post)) #f)
                ((apply lemma-in? y %postpositive) (loop (- k 1)))
                (else y)))))
    (define (question-end? i)
      (let loop ((k i))
        (let ((y (at k)))
          (cond ((not y) #f)
                ((string-contains (u y 'post) ";") #t)
                ((strong-stop? (u y 'post)) #f)
                (else (loop (+ k 1)))))))
    (define (first-finite i)
      ;; the first finite verb after I in its sentence, not past a relative
      ;; or subordinator
      (let loop ((k (+ i 1)))
        (let ((y (at k)))
          (cond ((not y) #f)
                ((finite? y) k)
                ((or (is? y "R") (apply lemma-in? y %mh-subordinators)) #f)
                ((strong-stop? (u y 'post)) #f)
                (else (loop (+ k 1)))))))
    (do ((i 0 (+ i 1))) ((>= i n) (vector->list v))
      (let* ((x (at i)) (p (prev-word i)) (nx (at (+ i 1))))
        (cond
         ((and (lemma-in? x "μή") (not (u x 'sense)))
          (let ((sub? (or (and p (or (apply lemma-in? p %mh-subordinators) (is? p "T" "R")
                                     ;; οὐ μή, οὐδὲ μή: the emphatic negation
                                     (lemma-in? p "οὐ" "οὐδέ")))
                          ;; ἐὰν ὀρθῶς προσενέγκῃς, ὀρθῶς δὲ μὴ διέλῃς: a subordinator
                          ;; earlier in the sentence (not before direct speech)
                          (let back ((k (- i 1)))
                            (let ((y (at k)))
                              (cond ((or (not y) (strong-stop? (u y 'post))) #f)
                                    ;; (one that takes the subjunctive: after εἰ ... , μὴ
                                    ;; παρέλθῃς is the apodosis, a prohibition)
                                    ((lemma-in? y "ἐάν" "ἵνα" "ὅπως" "ὅταν" "ἄν") #t)
                                    ((u y 'speech) #f)
                                    (else (back (- k 1)))))))))
            (cond
             ((lemma-in? nx "ποτέ") (vector-set! v i (u+ (set-sense x 'lest) 'opener #t)))
             (sub? #f)
             ((and (or (not p) (lemma-in? p "καί") (not (string-null? (u p 'post))) (u x 'speech) (u x 'cap))
                   (question-end? i) (first-finite i) (sense-of env "μή" 'question)
                   ;; Οὐκ ἐλάλησα ὑμῖν λέγων Μὴ ἀδικήσητε τὸ παιδάριον; the
                   ;; question mark is the frame's: speech nested after a verb
                   ;; of the same sentence opening with μή + second person
                   ;; subjunctive is a prohibition
                   (not (and (u x 'speech) (finite? nx) (eqv? (mood nx) #\S) (eqv? (tag-field (tp nx) 'person) #\2)
                             (let back ((k (- i 1)))
                               (let ((y (at k)))
                                 (cond ((or (not y) (strong-stop? (u y 'post))) #f)
                                       ((finite? y) #t)
                                       (else (back (- k 1)))))))))
              => (lambda (_)
                   (let ((k (first-finite i)))
                     (vector-set! v i (u+ (set-sense x 'question) 'yn-q #t))
                     (vector-set! v k (u+ (at k) 'yn-question #t)))))
             ((and (finite? nx) (eqv? (mood nx) #\S))
              (if (eqv? (tag-field (tp nx) 'person) #\2)
                  (vector-set! v (+ i 1) (u+ nx 'prohibit #t))
                  (when (sense-of env "μή" 'lest)
                    (vector-set! v i (u+ (set-sense x 'lest) 'opener #t))))))))
         ((and (lemma-in? x "μηδέ") (finite? nx) (eqv? (mood nx) #\S) (eqv? (tag-field (tp nx) 'person) #\2))
          (vector-set! v (+ i 1) (u+ nx 'prohibit #t))))))))

;;; Clauses: every unit gets 'cl, a number that changes where a clause opens
;;; (direct speech, a relative, a subordinator, καί before a finite verb).
;;; No word order rule moves a word into another clause.

(define %clause-openers
  '("ὅτι" "διότι" "ἵνα" "ὅπως" "εἰ" "ἐάν" "ὅταν" "ὅτε" "ἡνίκα" "ἐπεί" "ἐπειδή" "καθώς" "καθά" "καθότι"
    "ὡς" "ὥσπερ" "ὥστε" "πρίν" "ἀλλά" "ὅπου" "ὅθεν" "οὗ" "καθάπερ" "καθό" "ὅσος" "οἷος" "ἡνίκα" "ὅτε" "ἐπάν"))

(define (mark-questions units)
  "'in-question on every unit of a sentence that ends in a Greek question
mark (;), also past commas: Τί τοῦτο ἐποίησάς μοι, ὅτι ...;"
  (let loop ((us (reverse units)) (q? #f) (acc '()))
    (match us
      (() acc)
      ((x . rest)
       (let ((q? (cond ((string-contains (u x 'post) ";") #t)
                       ((strong-stop? (u x 'post)) #f)
                       (else q?))))
         (loop rest q? (cons (u+ x 'in-question q?) acc)))))))

(define (mark-clauses units)
  (let loop ((us (mark-questions units)) (cl 0) (acc '()))
    (match us
      (() (reverse acc))
      ((x . rest)
       (let* ((nx (and (pair? rest) (car rest)))
              (opens? (and (pair? acc)
                           (or (u x 'speech) (u x 'opener)
                               (and (is? x "R") (not (eq? (u x 'role) 'possessive)))
                               (and (apply lemma-in? x %clause-openers) (not (is? x "PREP"))
                                    ;; ὅσα ἐάν, οὗ ἐάν: "ever", inside the relative's clause
                                    (not (and (lemma-in? x "ἐάν") (is? (car acc) "R" "ADV"))))
                               (and (lemma-in? x "ἕως") (not (and nx (eqv? (case-of nx) #\G))))
                               (and (lemma-in? x "καί") nx
                                    (or (finite? nx)
                                        (and (lemma-in? nx "οὐ" "μή") (pair? (cdr rest)) (finite? (cadr rest))))))))
              (cl (if opens? (+ cl 1) cl)))
         (loop rest cl (cons (u+ x 'cl cl) acc)))))))

;;; Spans: runs of units ending at Greek punctuation.

(define (split-spans units)
  (let loop ((us units) (cur '()) (acc '()))
    (cond ((null? us) (reverse (if (null? cur) acc (cons (reverse cur) acc))))
          ((string-null? (u (car us) 'post)) (loop (cdr us) (cons (car us) cur) acc))
          (else (loop (cdr us) '() (cons (reverse (cons (car us) cur)) acc))))))

(define (move lst from to)
  "LST with the element at FROM moved to stand before index TO (TO <= FROM)."
  (let* ((x (list-ref lst from)) (rest (append (take lst from) (drop lst (+ from 1)))))
    (append (take rest to) (list x) (drop rest to))))

(define (move-range lst from end to)
  "LST with elements [FROM, END) moved before index TO (TO <= FROM)."
  (let ((seg (take (drop lst from) (- end from)))
        (rest (append (take lst from) (drop lst end))))
    (append (take rest to) seg (drop rest to))))

(define (index-where lst pred)
  (let loop ((l lst) (i 0)) (cond ((null? l) #f) ((pred (car l)) i) (else (loop (cdr l) (+ i 1))))))

(define %postpositive '("δέ" "γάρ" "οὖν" "μέν" "τέ"))

(define (move-postpositives span)
  "δέ, γάρ, οὖν, μέν, τε move to before the word they follow (clause start)."
  (let loop ((span span) (i 1))
    (cond ((>= i (length span)) span)
          ((and (apply lemma-in? (list-ref span i) %postpositive) (not (u (list-ref span i) 'moved)))
           ;; before the whole phrase of the word it follows: τὸν υἱὸν δέ "but
           ;; the son", μετὰ σοῦ γάρ "for with you"
           (let ((to (let back ((k (- i 1)))
                       (let ((y (and (> k 0) (list-ref span (- k 1)))))
                         (if (and y (or (is? y "PREP") (and (is? y "T" "A") (not (eq? (u y 'role) 'pronoun)))
                                        ;; οὐκ ἐμνήσθη δέ: "But did not remember", the
                                        ;; negation stays with its verb
                                        (and (lemma-in? y "οὐ" "μή") (= k (- i 1)))
                                        ;; εἰ μὴ γάρ "For if not"
                                        (and (lemma-in? y "εἰ" "ἐάν") (lemma-in? (list-ref span k) "μή" "οὐ")))
                                  (string-null? (u y 'post)) (not (apply lemma-in? y %postpositive)))
                             (back (- k 1))
                             k)))))
             (loop (move (list-set-copy span i (u+ (list-ref span i) 'moved #t)) i to) (+ i 1))))
          (else (loop span (+ i 1))))))

(define (list-set-copy lst i x) (append (take lst i) (list x) (drop lst (+ i 1))))

(define (merge-refs a b)
  "Unit B absorbing unit A's Greek words (A's refs first, and A's capital)."
  (u+ b 'refs (append (u a 'refs) (u b 'refs))
      'speech (or (u a 'speech) (u b 'speech)) 'cap (or (u a 'cap) (u b 'cap)) 'idx (min (u a 'idx) (u b 'idx))))

(define (merge-negation span)
  "οὐ / μή (and οὐ μή) before a finite verb join the verb: \"did not rain\"."
  (let loop ((span span) (i 0))
    (if (>= i (length span))
        span
        (let* ((x (list-ref span i))
               (y (and (< (+ i 1) (length span)) (list-ref span (+ i 1))))
               (z (and (< (+ i 2) (length span)) (list-ref span (+ i 2)))))
          (cond
           ;; μὴ φύλαξ τοῦ ἀδελφοῦ μού εἰμι ἐγώ; the question's verb comes up to
           ;; its μή, which stays unrendered: "Am I guard of my brother?"
           ((u x 'yn-q)
            (let ((k (index-where span (lambda (w) (u w 'yn-question)))))
              (loop (if (and k (> k (+ i 1))) (move span k (+ i 1)) span) (+ i 1))))
           ((memq (u x 'sense) '(lest question)) (loop span (+ i 1)))
           ;; οὐ μή σε ἐγκαταλείπω: the pronoun goes after the verb
           ((and (lemma-in? x "οὐ") (lemma-in? y "μή") z (is? z "P" "F") (not (eqv? (case-of z) #\N))
                 (< (+ i 3) (length span)) (finite? (list-ref span (+ i 3))))
            (let ((w (list-ref span (+ i 3))))
              (loop (append (take span i) (list (u+ (merge-refs x (merge-refs y w)) 'neg #t 'at-all #t) z) (drop span (+ i 4)))
                    (+ i 1))))
           ((and (lemma-in? x "οὐ") (lemma-in? y "μή") (finite? z))
            (loop (append (take span i) (list (u+ (merge-refs x (merge-refs y z)) 'neg #t 'at-all #t)) (drop span (+ i 3))) (+ i 1)))
           ;; οὐδὲ μή: "nor at all will you serve"
           ((and (lemma-in? x "οὐδέ") (lemma-in? y "μή") (finite? z))
            (loop (append (take span i)
                          (list (u+ (merge-refs (set-sense x 'nor) (merge-refs (set-sense y 'at-all) z)) 'neg #t 'at-all #t 'nor #t))
                          (drop span (+ i 3)))
                  (+ i 1)))
           ((and (lemma-in? x "οὐ" "μή") (finite? y))
            (loop (append (take span i) (list (u+ (merge-refs x y) 'neg #t)) (drop span (+ i 2))) (+ i 1)))
           (else (loop span (+ i 1))))))))

(define (np-internal-moves span)
  "Possessive and demonstrative pronouns before their noun (absorbing its
article), attributive adjectives before their noun."
  (define (transfer-helper lst to-idx from-idx)
    ;; The phrase's helper (and a speech-opening capital) move to its new
    ;; first word.
    (let ((from (list-ref lst from-idx)) (to (list-ref lst to-idx)))
      (list-set-copy (list-set-copy lst from-idx (u+ from 'helper "" 'speech #f))
                     to-idx (u+ to 'helper (u from 'helper) 'speech (or (u to 'speech) (u from 'speech))
                                'cap (or (u to 'cap) (u from 'cap))))))
  (let loop ((span span) (i 0))
    (if (>= i (length span))
        span
        (let* ((x (list-ref span i))
               (at (lambda (k) (and (>= k 0) (< k (length span)) (list-ref span k))))
               (p (at (- i 1))) (pp (at (- i 2))) (nx (at (+ i 1))))
          (cond
           ((u x 'moved) (loop span (+ i 1)))
           ;; an articular infinitive's subject goes before it as a
           ;; possessive: μετὰ τὸ γεννῆσαι αὐτόν "after his begetting"
           ((and (eq? (u x 'role) 'inf-subject) (not (u x 'moved)) p (infinitive? p))
            ;; τοῦ μὴ ἁμαρτεῖν σε "of your not sinning"
            (loop (move (list-set-copy span i (u+ x 'moved #t)) i (if (and pp (lemma-in? pp "μή")) (- i 2) (- i 1))) (+ i 1)))
           ;; οὗ εἵνεκεν: "on account of which" (the relative's "of" is the
           ;; preposition's)
           ((and (is? x "R") (eqv? (case-of x) #\G) (lemma-in? nx "ἕνεκα") (not (u nx 'moved)))
            (loop (move (list-set-copy (list-set-copy span i (u+ x 'helper "")) (+ i 1) (u+ nx 'moved #t 'speech (u x 'speech) 'cap (u x 'cap)))
                        (+ i 1) i)
                  (+ i 2)))
           ;; article + reflexive genitive + noun: "the women of himself"
           ;; (ταῖς ἑαυτοῦ γυναιξίν); English has no slot between.
           ((and (is? x "T") (is? nx "F") (eqv? (case-of nx) #\G) (not (u nx 'moved))
                 (at (+ i 2)) (is? (at (+ i 2)) "N") (agree? x (at (+ i 2))))
            (loop (move (list-set-copy span (+ i 1) (u+ nx 'moved #t)) (+ i 2) (+ i 1)) (+ i 1)))
           ;; article + πᾶς: "all the" (τὰ πάντα).
           ((and (is? x "T") (lemma-in? nx "πᾶς") (agree? x nx) (not (u nx 'moved)))
            (let ((span (move (list-set-copy span (+ i 1) (u+ nx 'moved #t)) (+ i 1) i)))
              (loop (transfer-helper span i (+ i 1)) (+ i 2))))
           ;; noun + possessive pronoun / demonstrative: before the article.
           ((and (memq (u x 'role) '(possessive post-demonstrative)) p)
            (let* ((art? (and pp (is? pp "T") (memq (u pp 'role) '(the unrendered)) (or (eq? (u x 'role) 'possessive) (agree? pp p))))
                   ;; τοῖς δυσὶν ἀδελφοῖς αὐτοῦ "to his two brothers", αἱ ἑπτὰ
                   ;; ἀμνάδες αὗται "these seven ewe lambs": past a numeral
                   (ppp (at (- i 3)))
                   (num-art? (and (not art?) pp (numeral? pp) ppp (is? ppp "T") (memq (u ppp 'role) '(the unrendered))
                                  (or (eq? (u x 'role) 'possessive) (agree? ppp p))))
                   (start (cond (art? (- i 2)) (num-art? (- i 3)) (else (- i 1))))
                   (span (if (or art? num-art?) (list-set-copy span start (u+ (at start) 'role 'absorbed)) span))
                   (span (list-set-copy span i (u+ x 'moved #t)))
                   (span (move span i start)))
              (loop (transfer-helper span start (+ start 1)) (+ i 1))))
           ;; noun + attributive article + not + adjective: "the not clean livestock"
           ((and (eq? (u x 'role) 'attributive) (lemma-in? nx "μή" "οὐ") (at (+ i 2)) (is? (at (+ i 2)) "A") p)
            (let* ((art? (and pp (is? pp "T") (agree? pp p)))
                   (to (- i 1))
                   (span (move-range (list-set-copy span (+ i 2) (u+ (at (+ i 2)) 'moved #t)) i (+ i 3) to)))
              (loop (if art? span (transfer-helper span to (+ to 3))) (+ i 3))))
           ;; noun + attributive article + adjective: "the sixth day".
           ((and (eq? (u x 'role) 'attributive) (is? nx "A") p)
            (let* ((art? (and pp (is? pp "T") (agree? pp p)))
                   (to (- i 1))
                   (span (move-range (list-set-copy span (+ i 1) (u+ nx 'moved #t)) i (+ i 2) to)))
              (loop (if art? span (transfer-helper span to (+ to 2))) (+ i 2))))
           ;; anarthrous noun + adjective (or one-word participle): before it.
           ((and (is? x "N") (not (u x 'phrase)) (not (and p (is? p "T") (agree? p x)))
                 nx (agree? x nx) (not (u nx 'moved))
                 ;; (not into direct speech: εἶπεν Λεία Μακαρία ἐγώ)
                 (not (u nx 'speech))
                 (or (and (is? nx "A") (not (lemma-in? nx "πᾶς"))
                          ;; not an adjective with its own complement (ὅμοιος αὐτῷ);
                          ;; a numeral has none (υἱὸν ἕνα τῷ κυρίῳ μου "one son")
                          (or (numeral? nx)
                              (let ((nn (at (+ i 2)))) (not (and nn (nominal? nn) (memv (case-of nn) '(#\G #\D)))))))
                     ;; (with a complement it stays after: σὰρξ κινουμένη ἐπὶ τῆς γῆς)
                     (and (participle? nx)
                          (let ((nn (at (+ i 2)))) (or (not nn) (is? nn "CONJ"))))))
            ;; a compound numeral moves whole: ἔτη τετρακόσια τριάκοντα
            ;; "four hundred thirty years"
            (let* ((end (if (numeral? nx)
                            (let run ((k (+ i 2)))
                              (let ((y (at k)))
                                (cond ((and y (numeral? y) (or (not (case-of y)) (agree? x y)) (string-null? (u (at (- k 1)) 'post))) (run (+ k 1)))
                                      ((and y (lemma-in? y "καί") (numeral? (at (+ k 1))) (not (case-of (at (+ k 1))))) (run (+ k 2)))
                                      (else k))))
                            (+ i 2)))
                   (span (move-range (list-set-copy span (+ i 1) (u+ nx 'moved #t)) (+ i 1) end i)))
              (loop (transfer-helper span i (+ i (- end i 1))) (+ i (- end i) 1))))
           (else (loop span (+ i 1))))))))

(define (move-verbal-subjects span)
  "The subject phrase of an articular infinitive goes before it as a
possessive (μετὰ τὸ διαχωρισθῆναι τὸν Λώτ \"after Lot's being separated\",
the last word taking \"'s\"); a genitive absolute's subject goes before its
participle in the nominative (καθημένου αὐτοῦ \"he being seated\", ἔτι
ζῶντος αὐτοῦ \"he still living\")."
  (define (block-end span k key)
    (let loop ((m k)) (if (and (< m (length span)) (u (list-ref span m) key)) (loop (+ m 1)) m)))
  (let loop ((span span) (i 0))
    (if (>= i (length span))
        span
        (let ((x (list-ref span i)))
          (cond
           ((and (infinitive? x) (u x 'gerund) (< (+ i 1) (length span)) (u (list-ref span (+ i 1)) 'inf-np))
            (let* ((end (block-end span (+ i 1) 'inf-np))
                   (span (list-set-copy span (- end 1) (u+ (list-ref span (- end 1)) 'poss-s #t)))
                   (to (if (and (> i 0) (lemma-in? (list-ref span (- i 1)) "μή")) (- i 1) i)))
              (loop (move-range span (+ i 1) end to) (+ i 1 (- end i 1)))))
           ((and (u x 'gabs) (< (+ i 1) (length span)) (u (list-ref span (+ i 1)) 'gabs-subj))
            (let* ((end (block-end span (+ i 1) 'gabs-subj))
                   (to (if (and (> i 0) (lemma-in? (list-ref span (- i 1)) "ἔτι")) (- i 1) i))
                   (span (append (take span (+ i 1))
                                 (map (lambda (y) (if (is? y "P" "F") (u+ y 'as-nominative #t) y)) (take (drop span (+ i 1)) (- end i 1)))
                                 (drop span end)))
                   (span (move-range span (+ i 1) end to))
                   ;; the participle's capital (a sentence start) goes to the subject
                   (span (if (u (list-ref span to) 'cap) span
                             (list-set-copy span to (u+ (list-ref span to) 'cap (u x 'cap))))))
              (loop span (+ i 1 (- end i 1)))))
           (else (loop span (+ i 1))))))))

;;; Subjects.

(define* (nom? x definite? #:optional prev)
  "X can be (part of) a subject: nominative, or with DEFINITE? #f a neuter
accusative (neuter nominative and accusative look alike); an indeclinable
name with no article. A participle or adjective only after its article
(ἔστω διαχωρίζον, γυμνοὶ ἦσαν are not subjects); not the first word of
direct speech."
  (and x (or (nominal? x) (u x 'phrase))
       (not (memq (u x 'role) '(possessive inf-subject)))
       ;; a vocative's apposition, a genitive absolute's or an infinitive's
       ;; subject is not the verb's
       (not (u x 'vocative)) (not (u x 'gabs-subj)) (not (u x 'inf-np)) (not (u x 'gabs)) (not (u x 'prep-obj))
       (or (not (or (participle? x) (and (is? x "A") (not (u x 'phrase)))))
           (and prev (is? prev "T") (agree? prev x))
           (lemma-in? x "πᾶς")   ; πᾶς ὁ λαός
           (u x 'moved))   ; an adjective moved before its noun (θεοὶ ἕτεροι)
       (or (eqv? (case-of x) #\N)
           (and (is? x "N") (not (case-of x)))
           (and (not definite?) (eqv? (case-of x) #\A) (eqv? (gen-of x) #\N)))))

(define (nom-or-participle? x prev definite?) (nom? x definite? prev))

(define* (np-word? x want definite? #:optional prev)
  "X can be a word of a noun phrase in case WANT (#\\N: nom?)."
  (if (eqv? want #\N)
      (nom? x definite? prev)
      (and x (or (nominal? x) (u x 'phrase))
           (not (memq (u x 'role) '(possessive inf-subject)))
           (or (not (or (participle? x) (and (is? x "A") (not (u x 'phrase)))))
               (and prev (is? prev "T") (agree? prev x))
               (lemma-in? x "πᾶς") (u x 'moved))
           (or (eqv? (case-of x) want) (and (is? x "N") (not (case-of x)))))))

(define (np-noun span k)
  "The first word from K that is not an article or a possessive moved before
its noun: the noun of the phrase starting at K."
  (find (lambda (y) (not (or (is? y "T" "A") (and (memq (u y 'role) '(possessive post-demonstrative)) (u y 'moved)))))
        (drop span (min k (length span)))))

(define (phrase-before span k)
  "The word before the noun phrase that K is in: past articles, adjectives and
possessives moved before their noun (καὶ αὐτοῦ ἡ γυνή: καί)."
  (let loop ((m (- k 1)))
    (let ((y (and (>= m 0) (list-ref span m))))
      (if (and y (or (is? y "T" "A") (and (memq (u y 'role) '(possessive post-demonstrative)) (u y 'moved))))
          (loop (- m 1))
          y))))

(define (caseless-name? x)(and x (is? x "N") (not (case-of x)) (tag-field (tp x) 'indeclinable) #t))

(define (neuter-plural? x) (and x (eqv? (gen-of x) #\N) (eqv? (num-of x) #\P)))

(define (plural-agreement verb words)
  "VERB, a third singular, with 'agree-number #\\P when the nouns of its
subject WORDS (before it) are neuter plural: τὰ πετεινὰ κατήσθιεν \"the birds
were devouring\" (the Greek neuter plural takes a singular verb)."
  (let ((nouns (filter (lambda (y) (and (is? y "N" "D") (memv (case-of y) '(#\N #\A)) (not (eq? (u y 'role) 'possessive)))) words)))
    (if (and (eqv? (num-of verb) #\S) (memv (tag-field (tp verb) 'person) '(#\3 #f))
             (pair? nouns) (every neuter-plural? nouns))
        (u+ verb 'agree-number #\P)
        verb)))

(define* (scan-np span j definite? #:key no-genitive? (want #\N) cl copula? env)
  "The whole noun phrase in case WANT starting at J, in the span's current
order: its head with article, adjectives, genitives, possessives,
attributive phrases, an agreeing participle with its complements, an
apposition, and members joined by καί, all inside clause CL (when given). As
(end coordinated? head starts), END exclusive, STARTS the indices where its
members and appositions begin; 'name-oblique when its head is an
indeclinable name followed by a person noun in another case (ἐκάλεσεν Ἠσαὺ
τὸν υἱὸν αὐτοῦ: Esau is in apposition to the object); or #f."
  (define (at k) (and (>= k 0) (< k (length span)) (list-ref span k)))
  (define (in-cl? x) (and x (or (not cl) (eqv? (u x 'cl) cl))))
  (define (word? x p) (and (in-cl? x) (np-word? x want definite? p)))
  (let loop ((k j) (state 'pre) (coord #f) (head #f) (starts (list j)) (arth #f))
    (let ((x (at k)) (p (at (- k 1))) (nx (at (+ k 1))))
      (define (done) (and head (list k coord head (reverse starts))))
      (case state
        ((pre)
         (cond ((not (in-cl? x)) (done))
               ;; a possessive already moved before its noun: "their adornment"
               ((and (memq (u x 'role) '(possessive post-demonstrative)) (u x 'moved)) (loop (+ k 1) 'pre coord head starts arth))
               ;; an interrogative, relative or the first word of direct speech
               ;; begins a new clause
               ((and (= k j) (or (is? x "I" "R") (u x 'speech))) #f)
               ((not (word? x p)) (done))
               ((and (not (u x 'phrase))
                     (or (and (is? x "T") nx)
                         (and (is? x "D") (word? nx x))
                         (and (is? x "A") nx (or (and (is? nx "T") (agree? x nx)) (word? nx x)
                                                 ;; πᾶς αὐτῶν ὁ κόσμος, the possessive moved forward
                                                 (and (eq? (u nx 'role) 'possessive) (u nx 'moved))))))
                (loop (+ k 1) 'pre coord head starts (or arth (is? x "T"))))
               (else (loop (+ k 1) 'post coord (or head x) starts (or arth (and p (is? p "T") (agree? p x)))))))
        ((post)
         (cond ((not (in-cl? x)) (done))
               ;; αἱ ἡμέραι τοῦ τεκεῖν αὐτήν "the days of her bearing": a
               ;; genitive articular infinitive goes with the noun before it,
               ;; with its own subject and object words
               ((and (is? x "T") (eq? (u x 'role) 'infinitive) (eqv? (case-of x) #\G) (not (eqv? want #\G))
                     ;; (only a gerund with its subject: not the purpose of
                     ;; ταχυνεῖ ὁ θεὸς τοῦ ποιῆσαι αὐτό)
                     (let find-inf ((m (+ k 1)))
                       (let ((y (at m)))
                         (cond ((not y) #f)
                               ((or (lemma-in? y "μή") (eq? (u y 'role) 'inf-subject)) (find-inf (+ m 1)))
                               (else (and (infinitive? y) (u y 'gerund)))))))
                (let skip ((m (+ k 1)))
                  (let ((y (at m)))
                    (if (and (in-cl? y) (or (lemma-in? y "μή") (infinitive? y) (memq (u y 'role) '(inf-subject)) (u y 'inf-np)))
                        (skip (+ m 1))
                        (loop m 'post coord head starts arth)))))
               ((and env (caseless-name? head) (eq? p head)
                     (let ((noun (np-noun span k)))
                       (and noun (is? noun "N") (case-of noun) (not (eqv? (case-of noun) want))
                            ;; (a name is singular: ἐνετείλατο Φαραὼ ἀνδράσιν; an
                            ;; apposition has its article: λήμψεται Ἰακὼβ γυναῖκα; and a
                            ;; genitive is the verb's: ἤκουσεν Ἰακὼβ τοῦ πατρός)
                            (not (eqv? (num-of noun) #\P)) (not (eqv? (case-of noun) #\G))
                            (any (lambda (y) (is? y "T")) (take-while (lambda (y) (not (eq? y noun))) (drop span k)))
                            (not (name-like? env noun)) (person-noun? env noun))))
                'name-oblique)
               ;; a genitive belongs to the phrase, unless the verb takes a
               ;; genitive object (ἐπλήσθη ἡ γῆ ἀδικίας: NO-GENITIVE?) nor
               ;; after a name with εἰμί (ἦν Νῶε ἐτῶν πεντακοσίων)
               ((and (not no-genitive?) (not (and copula? head (tag-field (tp head) 'indeclinable)))
                     ;; (a pronoun has no genitive: ἐφεισάμην ἐγώ σου)
                     (not (is? head "P" "F"))
                     (memv (case-of x) '(#\G)) (or (nominal? x) (u x 'phrase)) (not (is? x "R"))
                     ;; (a possessive moved before its own genitive noun only)
                     (or (not (eq? (u x 'role) 'possessive))
                         (and (u x 'moved)
                              (let ((y (find (lambda (y) (not (eq? (u y 'role) 'absorbed))) (drop span (+ k 1)))))
                                (and y (eqv? (case-of y) #\G) (is? y "N" "A")))))
                     ;; in a genitive phrase, only a noun (τῶν υἱῶν Χέτ)
                     (or (not (eqv? want #\G)) (is? x "N")))
                (loop (+ k 1) 'post coord head starts arth))
               ((and (memq (u x 'role) '(possessive post-demonstrative)) (not (u x 'moved))) (loop (+ k 1) 'post coord head starts arth))
               ((eq? (u x 'role) 'attributive) (loop (+ k 1) 'attr coord head starts arth))
               ;; σὰρξ κινουμένη ἐπὶ τῆς γῆς: an anarthrous participle agreeing
               ;; with an anarthrous common noun, with its complements
               ((and (participle? x) (eqv? (case-of x) want) (agree? head x) (not arth)
                     (is? head "N") (not (tag-field (tp head) 'indeclinable)) (not (u x 'moved))
                     ;; (after a name it is adverbial: ἠρνήσατο Σάρρα λέγουσα)
                     (not (and env (name-like? env head))))
                (loop (+ k 1) 'pcomp coord head starts arth))
               ;; an apposition: Ἰακὼβ ὁ υἱὸς αὐτοῦ, Ἀβιμέλεχ βασιλεὺς Γεράρων
               ;; a substantival participle's complements: τῶν εἰσπορευομένων εἰς τὴν πόλιν
               ((and (participle? p) (is? x "PREP") (at (- k 2)) (is? (at (- k 2)) "T")) (loop k 'pcomp coord head starts arth))
               ;; τῶν πετεινῶν καὶ τῶν κτηνῶν: genitives joined by καί stay with
               ;; the phrase they follow
               ((and (lemma-in? x "καί") p (eqv? (case-of p) #\G) (not (eqv? want #\G)) (in-cl? nx)
                     (eqv? (case-of nx) #\G) (is? nx "T" "N" "A"))
                (loop (+ k 1) 'post coord head starts arth))
               ((and (not copula?) (is? head "N" "P")
                     ;; an apposition names a person (Κύριον | τὰς πόλεις is the object)
                     env (let ((noun (np-noun span k))) (and noun (person-noun? env noun)))
                     (or (and (or (is? x "T") (and (is? x "N") (not (caseless-name? x))))
                              (eqv? (case-of x) want) (word? x p)
                              (or (not (is? x "T")) (and nx (is? nx "N" "A"))))
                         ;; ὁ παῖς σου Ἰακώβ "your servant Jacob": a name after the
                         ;; head and its possessive (right after a noun it would be
                         ;; that noun's genitive, assign-roles)
                         (and (caseless-name? x) (eq? p head) (is? head "N") (not (name-like? env head))
                              (in-cl? x) (memv want '(#\N)))
                         ;; ὁ υἱὸς αὐτοῦ, its possessive already moved before it
                         (and (memq (u x 'role) '(possessive post-demonstrative)) (u x 'moved)
                              (let ((y (find (lambda (y) (not (eq? (u y 'role) 'absorbed))) (drop span (+ k 1)))))
                                (and y (in-cl? y) (is? y "N" "A") (eqv? (case-of y) want))))))
                (loop k 'pre coord head (cons k starts) #f))
               ((and definite? (lemma-in? x "καί") (in-cl? nx)
                     (or (word? nx x) (and (lemma-in? nx "πᾶς") (eqv? (case-of nx) want))
                         ;; καὶ αὐτοῦ αἱ δύο θυγατέρες: a possessive moved before its noun
                         (and (memq (u nx 'role) '(possessive post-demonstrative)) (u nx 'moved)
                              (let ((noun (np-noun span (+ k 1))))
                                (and noun (in-cl? noun) (eqv? (case-of noun) want) (is? noun "N"))))))
                (loop (+ k 1) 'pre #t head (cons (+ k 1) starts) #f))
               (else (done))))
        ;; After an attributive article: one adjective or participle (with its
        ;; complements), or one preposition/adverb with its noun phrase
        ;; (τὸ ὑποκάτω τοῦ οὐρανοῦ).
        ((attr)
         (cond ((not (in-cl? x)) (done))
               ((participle? x) (loop (+ k 1) 'pcomp coord head starts arth))
               ((is? x "A") (loop (+ k 1) 'post coord head starts arth))
               ((is? x "PREP" "ADV") (loop (+ k 1) 'attr-obj coord head starts arth))
               (else (loop k 'post coord head starts arth))))
        ((attr-obj)
         (cond ((and (in-cl? x) (or (nominal? x) (u x 'phrase)) (not (eqv? (case-of x) #\N)))
                (loop (+ k 1) (if (is? x "T" "A" "D") 'attr-obj 'post) coord head starts arth))
               (else (loop k 'post coord head starts arth))))
        ;; A participle's complements: prepositional phrases and oblique noun
        ;; phrases (ὁ πορευόμενος ἐν τῷ πεδίῳ).
        ((pcomp)
         (cond ((not (in-cl? x)) (done))
               ((is? x "PREP")
                (let obj ((m (+ k 1)))
                  (let ((z (at m)))
                    (if (and (in-cl? z) (or (nominal? z) (u z 'phrase)) (not (eqv? (case-of z) #\N)) (not (is? z "R")))
                        (obj (+ m 1))
                        (loop m 'pcomp coord head starts arth)))))
               ((and (or (nominal? x) (u x 'phrase)) (memv (case-of x) '(#\A #\D)) (not (is? x "R")) (not (participle? x)))
                (loop (+ k 1) 'pcomp coord head starts arth))
               (else (loop k 'post coord head starts arth))))))))

(define %subordinators '("ἵνα" "ὅπως" "ἐάν" "ἄν" "ὅταν" "ἕως" "μή" "ὅς" "ὅστις" "εἰ" "ὅτι" "ἐπεί"))

(define (personal-subject person number gender)
  (case person
    ((#\1) (if (eqv? number #\P) "we" "I"))
    ((#\2) "you")
    (else (if (eqv? number #\P) "they" #f))))

(define (insert-let span vi at x)
  "A third person imperative at VI with its subject before it: \"let\" (owning
the verb's Greek) goes in at AT, the verb itself becomes its (cont) rest."
  (let ((marker `((let-marker . #t) (refs . ,(u x 'refs)) (idx . ,(u x 'idx)) (helper . "") (post . "")
                  (cap . ,(u x 'cap)) (speech . ,(u x 'speech)) (greek . ,(u x 'greek)) (neg . ,(u x 'neg))))
        (span (list-set-copy span vi (u+ x 'let-rest #t 'cap #f 'speech #f))))
    (append (take span at) (list marker) (drop span at))))

(define (participle-subjects env span)
  "A subject that follows the adverbial participle it agrees with moves before
it, as for a finite verb: ἰδόντες δὲ οἱ υἱοὶ τοῦ θεοῦ τὰς θυγατέρας \"But the
sons of God having seen the daughters\"."
  (let loop ((span span) (i 0))
    (if (>= i (length span))
        span
        (let* ((x (list-ref span i))
               (p (and (> i 0) (list-ref span (- i 1)))))
          (if (and (participle? x) (eqv? (case-of x) #\N) (not (and p (is? p "T"))) (not (u x 'moved))
                   ;; a perfect only before a finite verb of its clause (Εὐλογημένος
                   ;; Ἀβράμ, "Blessed Abram", has none)
                   (or (not (eqv? (tag-field (tp x) 'tense) #\R))
                       (any (lambda (y) (and (finite? y) (eqv? (u y 'cl) (u x 'cl)))) (drop span (+ i 1)))))
              (let* ((j (let skip ((k (+ i 1)) (left 2))
                          (let ((y (and (< k (length span)) (list-ref span k))))
                            (if (and y (> left 0) (is? y "P" "F") (not (eqv? (case-of y) #\N)) (eqv? (u y 'cl) (u x 'cl))
                                     (not (eq? (u y 'role) 'possessive)))
                                (skip (+ k 1) (- left 1))
                                k))))
                     (np (scan-np span j #t #:cl (u x 'cl) #:env env))
                     ;; οὐχ εὑροῦσα ἡ περιστερά: the subject goes before the negation
                     (to (if (and p (lemma-in? p "οὐ" "μή") (eqv? (u p 'cl) (u x 'cl))) (- i 1) i)))
                (if (and (pair? np) (let ((h (third np)))
                                      (and (or (eqv? (case-of h) #\N) (caseless-name? h))
                                           (memv (num-of h) (list (num-of x) #f))
                                           (memv (gen-of h) (list (gen-of x) #f)))))
                    (let ((end (first np)))
                      (loop (move-range (list-set-copy span i (u+ x 'moved #t)) j end to) (+ i (- end j) 1)))
                    (loop span (+ i 1))))
              (loop span (+ i 1)))))))

(define %particles '("out" "up" "away" "back" "forth" "in" "down" "off" "apart"))

(define (place-particles env span)
  "A verb whose English ends in a particle (\"send out\") puts an object
pronoun before it: ἐξαπέστειλεν αὐτόν \"sent him out\"."
  (let loop ((span span) (i 0))
    (if (>= i (- (length span) 1))
        span
        (let* ((x (list-ref span i))
               ;; (past an unrendered ἄν: ἐξαπέστειλα ἄν σε "would have sent you out")
               (skip (if (and (lemma-in? (list-ref span (+ i 1)) "ἄν") (eq? (u (list-ref span (+ i 1)) 'sense) 'unrendered)
                              (< (+ i 2) (length span)))
                         1 0))
               (nx (list-ref span (+ i 1 skip)))
               (tail (and (is? x "V") (not (u x 'let-rest)) (not (u x 'english)) (unit-sense env x)
                          (cadr (verb-base (unit-sense env x))))))
          (if (and tail (member tail %particles)
                   (is? nx "P" "F") (eqv? (case-of nx) #\A) (not (eq? (u nx 'role) 'possessive)))
              (let ((piece `((tail-piece . #t) (n . ,(u x 'n)) (refs . ()) (idx . ,(u x 'idx))
                             (text . ,tail) (helper . "") (post . "") (cap . #f))))
                (loop (append (take span i) (list (u+ x 'no-tail #t)) (take (drop span (+ i 1)) (+ skip 1)) (list piece)
                              (drop span (+ i 2 skip)))
                      (+ i 3 skip)))
              (loop span (+ i 1)))))))

(define (interrogative? x)
  (or (lemma-in? x "ποῦ" "πῶς" "πόθεν" "πότε")
      (and (lemma-in? x "τίς") (not (eqv? (case-of x) #\N)))
      (and (u x 'phrase) (equal? (u x 'fixed) "why"))))

(define (invert-questions env span)
  "In a question (Greek ;) an interrogative followed by its verb inverts
English-style: ποῦ εἶ \"where are you\", ἵνα τί συνέπεσεν τὸ πρόσωπόν σου
\"why did your face fall\" (the auxiliary before the subject)."
  (let* ((yn (index-where span (lambda (y) (u y 'yn-q))))
         (q (or yn
                (and (any (lambda (y) (u y 'in-question)) span)
                     (index-where span interrogative?)))))
    (if (not q)
        span
        (let ((k (index-where (drop span (+ q 1)) (if yn (lambda (y) (u y 'yn-question)) finite?))))
          (if (not k)
              span
              (let* ((vi (+ q 1 k)) (x (list-ref span vi))
                     (between (take (drop span (+ q 1)) k)))
                (cond
                 ((u x 'let-rest) span)
                 ;; (an unrendered ἄν between: πῶς ἂν κλέψαιμεν "how would we steal")
                 ((every (lambda (y) (and (lemma-in? y "ἄν") (eq? (u y 'sense) 'unrendered))) between)
                  (list-set-copy span vi (u+ x 'question #t)))
                 ;; Τί τοῦτο ἐποίησας ἡμῖν; τοῦτο is not the subject of a
                 ;; first or second person verb: "What [is] this you did to us?"
                 ((and (not yn) (lemma-in? (list-ref span q) "τίς") (memv (tag-field (tp x) 'person) '(#\1 #\2))
                       (= 1 (length between)) (is? (car between) "D") (eqv? (gen-of (car between)) #\N))
                  (append (take span (+ q 1))
                          (list `((supplied-piece . #t) (text . "[is]") (refs . ()) (helper . "") (post . "") (cap . #f)))
                          (drop span (+ q 1))))
                 ((or (every (lambda (y) (or (nom? y #f) (memq (u y 'role) '(possessive attributive absorbed)) (u y 'phrase)
                                             (and (eqv? (case-of y) #\G) (is? y "N" "T"))))
                             between)
                      ;; the whole subject phrase find-subjects moved there (ποῦ
                      ;; εἰσιν οἱ ἄνδρες οἱ εἰσελθόντες πρὸς σέ)
                      (and (u x 'subj-moved) (every (lambda (y) (eqv? (u y 'cl) (u x 'cl))) between)
                           (not (any finite? between))))
                  ;; The auxiliary goes before the subject, the rest after it.
                  (let ((marker `((let-marker . #t) (question-aux . #t) (refs . ,(u x 'refs)) (idx . ,(u x 'idx))
                                  (helper . "") (post . "") (cap . #f) (greek . ,(u x 'greek)) (verb . ,(u+ x 'question #t)))))
                    (append (take span (+ q 1)) (list marker) between
                            (list (u+ x 'question #t 'let-rest #t 'question-rest #t))
                            (drop span (+ vi 1)))))
                 (else span))))))))

(define (split-first s)
  "(first-word . rest) of S."
  (let ((i (string-index s #\space)))
    (if i (cons (substring s 0 i) (substring s (+ i 1))) (cons s ""))))

(define (gender-pronoun y)
  (if (eqv? (num-of y) #\P) "they" (case (gen-of y) ((#\F) "she") ((#\N) "it") (else "he"))))

(define (predicate-person? env span k)
  "The word at K is an anarthrous nominative common noun naming a person: with
εἰμί or γίνομαι, the predicate (ἐγένετο δὲ τοξότης, ὅτι προφήτης ἐστίν)."
  (let ((y (list-ref span k)) (p (and (> k 0) (list-ref span (- k 1)))))
    (and (is? y "N") (eqv? (case-of y) #\N) (not (u y 'phrase)) (not (name-like? env y)) (person-noun? env y)
         (not (and p (is? p "T") (agree? p y)))
         (not (memq (u y 'role) '(absorbed))))))

(define (find-subjects env span)
  "Move a whole subject phrase that follows its finite verb in the same clause
to stand before the verb; give a verb with no subject in its clause the
pronoun of its ending; mark third person imperatives for \"let\". Where the
subject cannot be told apart (an indeclinable name in apposition to an
oblique noun, two nominatives), leave the Greek order and mark the verb
'subject-unsure for `check` (gsb/literal/README.md)."
  (let loop ((span span) (i 0))
    (if (>= i (length span))
        span
        (let ((x (list-ref span i)))
          (if (or (not (finite? x)) (u x 'subj-done))
              (loop span (+ i 1))
              (let* ((cl (u x 'cl))
                     (n (length span))
                     (at (lambda (k) (and (>= k 0) (< k n) (list-ref span k))))
                     (in-cl? (lambda (y) (and y (eqv? (u y 'cl) cl))))
                     (person (tag-field (tp x) 'person))
                     (number (tag-field (tp x) 'number))
                     (imper (eqv? (mood x) #\M))
                     (copula (lemma-in? x "εἰμί" "γίνομαι"))
                     ;; The clause runs back to its opening word (inclusive: ὃ
                     ;; ἦν), a conjunction or another finite verb (exclusive).
                     (clause-start (let back ((k (- i 1)))
                                     (let ((y (at k)))
                                       (cond ((not (in-cl? y)) (+ k 1))
                                             ((is? y "R") k)
                                             ((or (is? y "CONJ") (finite? y)) (+ k 1))
                                             (else (back (- k 1)))))))
                     (clause-end (let fwd ((k (+ i 1))) (if (in-cl? (at k)) (fwd (+ k 1)) k)))
                     (before (take (drop span clause-start) (- i clause-start)))
                     (after (take (drop span (+ i 1)) (- clause-end i 1)))
                     (before-noms (filter (lambda (k) (and (nom? (at k) #t (at (- k 1)))
                                                           ;; (not a preposition's object: μετὰ δὲ ταῦτα ἐξελεύσονται)
                                                           (not (is? (phrase-before span k) "PREP"))
                                                           ;; καὶ Λὼτ τὸν ἀδελφὸν αὐτοῦ ἀπέστρεψεν: a name with
                                                           ;; an oblique apposition is in that case
                                                           (not (and (caseless-name? (at k))
                                                                     (let ((noun (np-noun span (+ k 1))))
                                                                       (and noun (is? noun "N") (memv (case-of noun) '(#\A #\D))
                                                                            (person-noun? env noun) (not (name-like? env noun))
                                                                            (is? (at (+ k 1)) "T" "P")))))))
                                          (iota (- i clause-start) clause-start)))
                     (x (u+ x 'subj-done #t
                            'may (and (eqv? (mood x) #\S) (any (lambda (y) (lemma-in? y "ἵνα" "ὅπως")) (take span i))))))
                (define (dative-possessor?)
                  ;; καὶ τῷ Σὴθ ἐγένετο υἱός: a bare dative (it has "to") makes
                  ;; the person noun the subject, "son came to be to Seth"
                  (any (lambda (y) (and (eqv? (case-of y) #\D) (not (string-null? (u y 'helper))))) (append before after)))
                (define (gender-cue)
                  ;; συλλαβοῦσα ἔτεκεν "she bore", ἦν οἰκοδομῶν "he was building":
                  ;; a nominative singular participle, adjective or pronoun of
                  ;; the clause; with εἰμί/γίνομαι also a predicate person noun.
                  (let ((w (find (lambda (y) (and (or (participle? y) (is? y "A" "P" "D")) (not (memq (u y 'role) '(possessive)))
                                                  (not (u y 'gabs-subj)) (not (u y 'gabs))
                                                  (eqv? (case-of y) #\N) (eqv? (num-of y) #\S) (gen-of y)))
                                 (append before (take-while (lambda (y) (not (or (finite? y) (lemma-in? y "καί")))) after)))))
                    (cond (w (gender-pronoun w))
                          ((and copula (not (dative-possessor?))
                                (find (lambda (k) (and (predicate-person? env span k) (eqv? (num-of (at k)) (or number #\S))))
                                             (append (iota (- i clause-start) clause-start) (iota (length after) (+ i 1)))))
                           => (lambda (k) (gender-pronoun (at k))))
                          (else #f))))
                (cond
                 ;; A word override's (subject ...) always wins.
                 ((string? (u x 'subject))
                  (loop (list-set-copy span i (u+ x 'subj (u x 'subject))) (+ i 1)))
                 ((memv person '(#\1 #\2))
                  ;; An explicit ἐγώ / σύ in the clause, or a nominative relative
                  ;; before the verb (ὅστις ἐξήγαγον), is the subject; after the
                  ;; verb it moves before it with its phrase (φοβῇ τὸν θεὸν σύ
                  ;; "you fear God", ἀποθανῇ σὺ καὶ πάντα τὰ σά).
                  (let* ((own? (lambda (y) (and (is? y "P") (eqv? (case-of y) #\N) (eqv? (tag-field (tp y) 'person) person))))
                         (explicit-before (or (any own? before) (any (lambda (y) (and (is? y "R") (eqv? (case-of y) #\N))) before)))
                         ;; (an imperative keeps it after: Πίε σύ "Drink you")
                         ;; (nor after an interrogative: τίς εἶ σύ "who are you")
                         (pk (and (not explicit-before) (not imper) (not (any (lambda (y) (is? y "I")) before))
                                  (list-index own? after)))
                         (pk (and pk (+ i 1 pk)))
                         ;; (with εἰμί the nominative after the subject is the
                         ;; predicate: ἐσόμεθα ἡμεῖς καὶ ἡ γῆ ἡμῶν παῖδες Φαραώ)
                         (np (and pk (scan-np span pk #t #:cl cl #:env env #:copula? copula)))
                         ;; καὶ ἡμεῖς καὶ σύ: the first καί, "both", goes with it
                         (both (and pk (pair? np) (second np) (> pk (+ i 1)) (lemma-in? (at (- pk 1)) "καί") (in-cl? (at (- pk 1)))
                                    (not (u (at (- pk 1)) 'sense)) (sense-of env "καί" 'both)))
                         (span (if both (list-set-copy span (- pk 1) (set-sense (at (- pk 1)) 'both)) span))
                         (pk (if both (- pk 1) pk))
                         (end (if (pair? np) (first np) (and pk (+ pk 1))))
                         ;; ἀδελφὴ αὐτοῦ εἰμι, γυνὴ εὐπρόσωπος εἶ: a nominative
                         ;; before a first/second person εἰμί is its predicate and
                         ;; goes after it: "I am his sister"
                         (run-start (and copula (not explicit-before) (pair? before-noms)
                                         (not (any (lambda (y) (is? y "I")) before))
                                         (let ((r (let back ((k (nominative-run span i clause-start #t)))
                                                    (let ((y (at (- k 1))))
                                                      (if (and (> k clause-start) y (u y 'moved) (memq (u y 'role) '(possessive post-demonstrative)))
                                                          (back (- k 1))
                                                          k)))))
                                           (and (<= r (apply min before-noms)) (< r i) r))))
                         (i0 (or run-start i))
                         (span (if run-start
                                   (let* ((first-word (at run-start))
                                          (sp (u first-word 'speech))
                                          (span (list-set-copy span run-start (u+ first-word 'speech #f 'cap (and (not sp) (u first-word 'cap)))))
                                          (span (list-set-copy span i (u+ x 'speech (or sp (u x 'speech)) 'cap (or sp (u x 'cap))))))
                                     (move span i run-start))
                                   span))
                         (x (if run-start (list-ref span i0) x))
                         (span (if pk (move-range span pk end i0) span))
                         (vi (if pk (+ i0 (- end pk)) i0)))
                    (loop (list-set-copy span vi (u+ x 'subj (if (or explicit-before (any own? after) imper (u x 'prohibit)) #f (personal-subject person number #f))
                                                     'hortatory (and (eqv? (mood x) #\S) (eqv? person #\1) (eqv? number #\P)
                                                                     (not (u x 'yn-question))
                                                                     (not (any (lambda (y) (apply lemma-in? y %subordinators)) (take span i))))
                                                     'may (and (memv (mood x) '(#\S)) (any (lambda (y) (lemma-in? y "ἵνα" "ὅπως")) (take span i)))))
                          (+ vi 1))))
                 ((and (pair? before-noms) copula (not (u x 'neg)) (not (dative-possessor?))
                       (every (lambda (k) (and (predicate-person? env span k) (eqv? (num-of (at k)) #\S))) before-noms)
                       ;; right before the verb, and no subject after it (Γυνὴ αὐτοῦ ἐστιν αὕτη)
                       (>= (apply min before-noms) (nominative-run span i clause-start #t))
                       (not (any (lambda (y) (nom? y #t)) after)))
                  ;; ὅτι προφήτης ἐστίν: an anarthrous person noun before εἰμί is
                  ;; the predicate; its gender is the subject's, and it goes after
                  ;; the verb: "that he is prophet", Ἀδελφή μού ἐστιν "She is my sister".
                  (let* ((run-start (let back ((k (nominative-run span i clause-start #t)))
                                      ;; with its possessive moved before it (σου γυνή)
                                      (let ((y (at (- k 1))))
                                        (if (and (> k clause-start) (or (u y 'moved) (eq? (u y 'role) 'absorbed))
                                                 (memq (u y 'role) '(possessive absorbed post-demonstrative)))
                                            (back (- k 1))
                                            k))))
                         (x (u+ x 'subj (gender-pronoun (at (car before-noms)))))
                         (first-word (at run-start))
                         ;; the run's speech capital passes to the verb
                         (x (if (u first-word 'speech) (u+ x 'speech #t 'cap #t) x))
                         (span (if (u first-word 'speech) (list-set-copy span run-start (u+ first-word 'speech #f 'cap #f)) span)))
                    (loop (move (list-set-copy span i x) i run-start) (+ i 1))))
                 ((pair? before-noms)
                  ;; Subject already before the verb; a third person imperative's
                  ;; "let" goes before the nominative run touching the verb.
                  (let ((run-start (nominative-run span i clause-start #t))
                        (x (plural-agreement x (map at before-noms))))
                    (if (and imper (< run-start i))
                        (loop (insert-let span i run-start x) (+ i 2))
                        (loop (list-set-copy span i x) (+ i 1)))))
                 (else
                  ;; The subject may follow object pronouns, an adverb or one
                  ;; prepositional phrase: εὐλόγησεν αὐτοὺς ὁ θεός; λαλείτω πρὸς
                  ;; ἡμᾶς ὁ θεός; ᾠκοδόμησεν ἐκεῖ Ἀβράμ; and an adverbial καί
                  ;; goes with it (ἔτεκεν δὲ καὶ ἡ νεωτέρα "but also the younger bore").
                  (let* ((j (let skip ((k (+ i 1)) (left 2) (pp 1) (adv 1) (obl 1))
                              (let ((y (at k)))
                                (cond ((not (in-cl? y)) k)
                                      ;; one object noun phrase whose case is plain (a
                                      ;; masculine/feminine accusative, a dative) when a
                                      ;; nominative follows it: ἕξει υἱὸν Σάρρα ἡ γυνή σου;
                                      ;; ἔσται τῇ Σάρρᾳ υἱός
                                      ((and (> obl 0) (or (is? y "T" "N" "A") (and (memq (u y 'role) '(possessive)) (u y 'moved)))
                                            (let ((noun (np-noun span k)))
                                              (and noun (in-cl? noun) (is? noun "N") (not (caseless-name? noun))
                                                   (or (eqv? (case-of noun) #\D)
                                                       (and (eqv? (case-of noun) #\A) (memv (gen-of noun) '(#\M #\F)))))))
                                       (let obj ((m k) (c #f))
                                         (let ((z (at m)))
                                           (if (and (in-cl? z) (or (is? z "T" "N" "A") (eq? (u z 'role) 'possessive))
                                                    (not (eqv? (case-of z) #\N)) (not (caseless-name? z))
                                                    (if c (or (eqv? (case-of z) c) (eqv? (case-of z) #\G)) #t))
                                               (obj (+ m 1) (or c (and (not (eq? (u z 'role) 'possessive)) (case-of z))))
                                               ;; only if a nominative comes next
                                               (if (and (in-cl? z) (nom? z #t (at (- m 1))))
                                                   (skip m left pp adv 0)
                                                   k)))))
                                      ((and (> left 0) (is? y "P" "F") (not (eqv? (case-of y) #\N)) (not (eq? (u y 'role) 'possessive)))
                                       (skip (+ k 1) (- left 1) pp adv obl))
                                      ;; (also a particle: λημφθήτω δὴ ὕδωρ)
                                      ((and (> adv 0) (is? y "ADV" "PRT") (not (interrogative? y)) (not (lemma-in? y "οὐ" "μή" "οὐδέ" "μηδέ" "τέ")))
                                       (skip (+ k 1) left pp (- adv 1) obl))
                                      ((and (> pp 0) (is? y "PREP"))
                                       ;; the object: words in its first word's case and
                                       ;; their genitives (παρὰ τῷ θεῷ | ῥῆμα)
                                       (let obj ((m (+ k 1)) (c #f))
                                         (let ((z (at m)))
                                           (if (and (in-cl? z) (or (nominal? z) (u z 'phrase)) (not (eqv? (case-of z) #\N))
                                                    (if c (or (eqv? (case-of z) c) (eqv? (case-of z) #\G)) #t)
                                                    ;; μετὰ κράτους | αὐτῶν τὰ τόξα: a possessive moved
                                                    ;; before the next noun after a noun is not the object's
                                                    (not (and (eq? (u z 'role) 'possessive) (u z 'moved) (is? (at (- m 1)) "N"))))
                                               (obj (+ m 1) (or c (and (not (eq? (u z 'role) 'possessive)) (case-of z))))
                                               (skip m left 0 adv obl)))))
                                      (else k)))))
                         ;; (also τε of ὅ τε Ἀδὰμ καὶ ἡ γυνή, moved before its article)
                         (kai-k (and (lemma-in? (at j) "καί" "τέ") (in-cl? (at (+ j 1))) (nom? (at (+ j 1)) #t (at j)) j))
                         (j (if kai-k (+ j 1) j))
                         ;; A neuter noun may be the subject when the verb is not
                         ;; active, is εἰμί or an imperative, or its object is
                         ;; already taken by a relative (ἃ ἐξήγαγεν τὰ ὕδατα) or a
                         ;; pronoun (μὴ καταλάβῃ με τὰ κακά).
                         ;; (a middle is transitive: ἐπεκαλέσατο ἐκεῖ τὸ ὄνομα Κυρίου)
                         (neuter-ok (or imper copula (eqv? (tag-field (tp x) 'voice) #\P)
                                        (assq 'intransitive (cdr (or (unit-sense env x) '(#f))))
                                        (any (lambda (y) (and (is? y "R") (eqv? (case-of y) #\A))) before)
                                        (any (lambda (y) (and (is? y "P") (eqv? (case-of y) #\A) (not (memq (u y 'role) '(inf-subject possessive)))))
                                             (append before after))))
                         (gen-object? (and (field (unit-sense env x) 'genitive) #t))
                         ;; (a passive of naming takes a predicate, not an apposition:
                         ;; ἐκλήθη τὸ ὄνομα αὐτοῦ Σύγχυσις)
                         (no-appos (or copula (and (eqv? (tag-field (tp x) 'voice) #\P) (lemma-in? x "καλέω" "ὀνομάζω" "ἐπονομάζω"))))
                         (np (or (scan-np span j #t #:no-genitive? gen-object? #:cl cl #:copula? no-appos #:env env)
                                 (and neuter-ok (scan-np span j #f #:no-genitive? gen-object? #:cl cl #:copula? no-appos #:env env))))
                         (s (at j))
                         ;; After εἰμί an anarthrous common noun is the predicate
                         ;; (ἦν σφυροκόπος): not moved. An articular subject (also
                         ;; behind a possessive: αἱ ἡμέραι αὐτῶν), a demonstrative,
                         ;; a pronoun or a name (ἦν Νῶε, ποῦ ἐστιν Ἅβελ) is the
                         ;; subject and moves. After γίνομαι an anarthrous person
                         ;; noun is the predicate (ἐγένετο δὲ τοξότης), a thing the
                         ;; subject (ἐγένετο φῶς).
                         (nominative-after
                          (and (pair? np)
                               (or (and (lemma-in? x "εἰμί")
                                        (not (or (is? s "T" "D" "P") (and (eq? (u s 'role) 'possessive) (u s 'moved))
                                                 (name-like? env s))))
                                   (and (lemma-in? x "γίνομαι") (predicate-person? env span j) (not (dative-possessor?))))))
                         (np (if nominative-after #f np))
                         (end (and (pair? np) (first np)))
                         (head (and (pair? np) (third np)))
                         ;; Two candidates: a name with a declined nominative after
                         ;; it, or a second nominative after a non-copula verb's
                         ;; subject. Stiff Greek order beats a wrong actor.
                         ;; (a passive of naming takes a predicate: ἐκλήθη τὸ ὄνομα αὐτοῦ
                         ;; Σύγχυσις; a later member joined by καί is the subject's:
                         ;; ἀνέβη Ἀβρὰμ ... αὐτὸς καὶ ἡ γυνὴ αὐτοῦ)
                         (unsure (or (eq? np 'name-oblique)
                                     (and (pair? np) (not copula) (not (eqv? (tag-field (tp x) 'voice) #\P))
                                          (caseless-name? head)
                                          (any (lambda (k) (let ((y (at k)))
                                                             ;; (a neuter may be accusative: τὸ πρωί)
                                                             (and (nom? y #t (at (- k 1))) (case-of y) (not (participle? y)) (not (is? y "P" "R" "T"))
                                                                  ;; (the name given: ἐκάλεσεν Ἀδὰμ τὸ ὄνομα ... Ζωή)
                                                                  (not (u y 'keep-cap))
                                                                  (not (eqv? (gen-of y) #\N))
                                                                  (not (u y 'phrase))
                                                                  (let ((w (phrase-before span k)))
                                                                    (not (and w (lemma-in? w "καί" "ἐκ" "ἀπό" "εἰς" "ἐν" "ἐπί" "πρός" "παρά" "μετά" "διά" "κατά" "περί" "ὑπό"))))
                                                                  (not (is? (phrase-before span k) "PREP")))))
                                               (iota (max 0 (- clause-end end)) end)))))
                         (ok (and (pair? np) (not unsure)
                                  ;; (ἐγώ is no third person verb's subject: ταῦτά ἐστιν
                                  ;; ἐγὼ ἐν γαστρὶ ἔχω)
                                  (not (and (is? head "P") (memv (tag-field (tp head) 'person) '(#\1 #\2))))
                                  ;; ἐγένετο μετὰ τὰ ῥήματα ταῦτα ὁ θεὸς ἐπείραζεν: before
                                  ;; another finite verb of its clause, the nominative is
                                  ;; that verb's, not the impersonal's
                                  (not (and (field1 (unit-sense env x) 'subject)
                                            (any (lambda (k) (finite? (at k))) (iota (max 0 (- clause-end end)) end))))
                                  (or (second np) (eqv? (num-of head) number) (not (num-of head))
                                      (and (eqv? (gen-of head) #\N) (eqv? number #\S)))))
                         (pronoun-object? (any (lambda (y) (and (is? y "P") (eqv? (case-of y) #\A) (not (memq (u y 'role) '(inf-subject possessive)))
                                                                (not (eqv? (tag-field (tp y) 'person) #\1)) (not (eqv? (tag-field (tp y) 'person) #\2))))
                                               after))
                         (run-start (and (not ok) (not unsure)
                                         ;; (not for a pronoun object: τί καλέσει αὐτά)
                                         (or imper (lemma-in? x "εἰμί") (not (memv (tag-field (tp x) 'voice) '(#\A)))
                                             (assq 'intransitive (cdr (or (unit-sense env x) '(#f))))
                                             (any (lambda (y) (and (is? y "R") (eqv? (case-of y) #\A))) before)
                                             ;; τὰ πετεινὰ ... κατήσθιεν αὐτά: the verb's object is a
                                             ;; pronoun after it, so the neuter before it is the subject
                                             (and pronoun-object? (eqv? person #\3)
                                                  (any (lambda (y) (and (is? y "N") (neuter-plural? y))) before)
                                                  (not (any (lambda (y) (nom? y #t)) after))))
                                         (nominative-run span i clause-start #f
                                                         ;; ὃ ἦν: a neuter relative is the subject
                                                         ;; of εἰμί or a passive, not of an active verb
                                                         (or imper (lemma-in? x "εἰμί") (not (memv (tag-field (tp x) 'voice) '(#\A)))))))
                         ;; ὅσα τῷ πλησίον σού ἐστιν: a neuter subject before εἰμί,
                         ;; not next to it, still leaves no pronoun to supply.
                         (neuter-before (and (not ok) (lemma-in? x "εἰμί")
                                             (any (lambda (y) (and (nom? y #f) (not (is? y "P")))) before)))
                         (subj (and (not ok) (personal-subject person number #f))))
                    (cond
                     ((and run-start (< run-start i))
                      (let ((x (plural-agreement x (map at (iota (- i run-start) run-start)))))
                        (if imper
                            (loop (insert-let span i run-start x) (+ i 2))
                            (loop (list-set-copy span i x) (+ i 1)))))
                     (ok
                      (let* ((start (or kai-k j))
                             (span (if (and kai-k (not (u (at kai-k) 'sense)) (sense-of env "καί" 'also))
                                       (list-set-copy span kai-k (set-sense (at kai-k) 'also))
                                       span))
                             ;; (Μελχὰ καὶ αὐτή "Milcah, also she": not two subjects)
                             (x (if (and (eqv? number #\S)
                                         (or (and (second np) (not (any (lambda (k) (and (lemma-in? (at k) "αὐτός") (eqv? (case-of (at k)) #\N))) (fourth np))))
                                             (neuter-plural? head)))
                                    (u+ x 'agree-number #\P)
                                    x))
                             (span (move-range (list-set-copy span i (u+ x 'subj-moved #t)) start end i))
                             (vi (+ i (- end start))))
                        (if imper
                            (loop (insert-let span vi i x) (+ vi 2))
                            (loop span (+ vi 1)))))
                     (unsure
                      (loop (list-set-copy span i (u+ x 'subj "" 'subject-unsure #t)) (+ i 1)))
                     (else
                      ;; Rule 16a: the pronoun of a verb ending is never chosen
                      ;; from a nearby noun's meaning.
                      (loop (list-set-copy span i (u+ x 'subj (or (and nominative-after (lemma-in? x "γίνομαι") (gender-pronoun s))
                                                                  ;; ποῦ ἐστιν Ἅβελ: the nominative after εἰμί is enough
                                                                  (and (or nominative-after neuter-before) "")
                                                                  ;; true impersonals (ἐγένετο "it came to be")
                                                                  (field1 (unit-sense env x) 'subject)
                                                                  ;; καὶ συνέλαβεν: joined to the verb before, no pronoun
                                                                  (and (u x 'kai-joined) (not imper) "")
                                                                  subj
                                                                  (gender-cue)
                                                                  "he/she/it")))
                            (+ i 1)))))))))))))

(define* (nominative-run span i clause-start definite? #:optional relative-ok?)
  "Start of the run of subject words that ends right before index I (I when
there is none): nominatives with their genitives (πνεῦμα θεοῦ)."
  (let back ((k (- i 1)) (start i))
    (if (and (>= k clause-start)
             (let ((y (list-ref span k)))
               (or (and (nom-or-participle? y (and (> k 0) (list-ref span (- k 1))) definite?)
                        (not (is? (phrase-before span k) "PREP"))
                        (or definite? (not (is? y "R" "P" "K")) (and relative-ok? (is? y "R"))))
                   (memq (u y 'role) '(possessive post-demonstrative attributive))
                   (and (eqv? (case-of y) #\G) (is? y "N" "T" "A")))))
        (back (- k 1)
              (if (nom-or-participle? (list-ref span k) (and (> k 0) (list-ref span (- k 1))) definite?) k start))
        start)))

;;; English for one unit.

(define (be-form tense person number)
  (case tense
    ((present) (cond ((and (eqv? person #\1) (eqv? number #\S)) "am")
                     ((and (eqv? person #\3) (eqv? number #\S)) "is")
                     (else "are")))
    (else (if (and (memv person '(#\1 #\3)) (eqv? number #\S)) "was" "were"))))

(define (verb-base sense)
  "(head tail past pp) of a verb sense: its (verb ...) field or first gloss."
  (let* ((v (field sense 'verb))
         (phrase (if (pair? v) (car v) (gloss1 sense)))
         (words (string-split phrase #\space))
         (head (car words))
         (tail (string-join (cdr words) " "))
         ;; (verb "come back" "came back" "come back"), the convention, or
         ;; (verb "come back" "came" "come"): the particle is added once
         (bare (lambda (f) (if (and (not (string-null? tail)) (string-suffix? (string-append " " tail) f))
                               (substring f 0 (- (string-length f) (string-length tail) 1))
                               f))))
    (list head tail
          (if (and (pair? v) (>= (length v) 2)) (bare (second v)) (english-past head))
          (if (and (pair? v) (>= (length v) 3)) (bare (third v)) (english-pp head)))))

(define (verb-english env x)
  "Verb phrase words for verb unit X as (let-part . rest): LET-PART is \"let\"
for a third person imperative whose subject stands between, else #f."
  (match-let* ((sense (unit-sense env x))
               ((head tail past pp) (verb-base sense))
               (t (tp x))
               (tense (tag-field t 'tense)) (voice (tag-field t 'voice)) (m (tag-field t 'mood))
               (person (or (tag-field t 'person) #\3))
               ;; τὰ ἔντερα συνεστρέφετο: a singular verb with a neuter plural
               ;; (or a coordinated) subject is plural in English (find-subjects)
               (number (or (u x 'agree-number) (tag-field t 'number) #\S))
               (be? (string=? head "be"))
               (passive (and (eqv? voice #\P) (not (equal? (field1 sense 'voice) 'active)) (not be?)))
               (neg (u x 'neg))
               (oida (lemma-in? x "οἶδα"))
               (tense (cond ((and oida (eqv? tense #\R)) #\P) ((and oida (eqv? tense #\L)) #\A) (else tense))))
    ;; 'no-tail: the particle ("out" of "send out") goes after the object
    ;; pronoun as its own (cont) piece: "sent him out".
    (define (w . parts) (string-join (filter (lambda (s) (and s (not (string-null? s))))
                                             (append parts (list (if (u x 'no-tail) "" tail))))
                                     " "))
    (define (neg-aux aux . rest) (apply w aux (and neg "not") rest))
    (define (simple form do-form)
      ;; One-word finite form; negation needs do-support.
      ;; A question takes do-support too: "why did your face fall".
      (if (or neg (u x 'question)) (w do-form (and neg "not") head) (w form)))
    (define (participial)
      (case tense
        ((#\A) (if passive (w (and neg "not") "having been" pp) (w (and neg "not") "having" pp)))
        ((#\R) (if passive (w (and neg "not") pp) (w (and neg "not") "having" pp)))
        ((#\F) (w (and neg "not") "about to" head))
        (else (if passive (w (and neg "not") "being" pp) (w (and neg "not") (english-ing head))))))
    (define (infinitival)
      (if (u x 'gerund)
          (if passive (w "being" pp) (w (and neg "not") (english-ing head)))
          (case tense
            ((#\R) (w (and neg "not") "to have" (if passive "been" #f) pp))
            (else (if passive (w (and neg "not") "to be" pp) (w (and neg "not") "to" head))))))
    (define (base-form) (if passive (w "be" pp) (w head)))
    (case m
      ((#\P) (cons #f (participial)))
      ((#\N) (cons #f (infinitival)))
      ((#\M)
       (if (eqv? person #\3)
           (if (u x 'let-rest)
               (cons "let" (if passive (w "be" pp) (w head)))
               (cons "let" (if passive (w (and neg "not") "be" pp) (w (and neg "not") head))))
           (cons #f (if neg (if passive (w "do not be" pp) (w "do not" head)) (base-form)))))
      ((#\S #\O)
       (cons #f
             (cond ((u x 'nor) (if passive (w "nor at all will" (u x 'subj) "be" pp) (w "nor at all will" (u x 'subj) head)))
                   ((u x 'at-all) (string-append (if passive (w "will not be" pp) (w "will not" head)) " at all"))
                   ((and neg (u x 'hortatory)) (w "not" head))
                   ((and (u x 'would) (eqv? m #\O)) (if passive (w "would" (and neg "not") "be" pp) (w "would" (and neg "not") head)))
                   ((or (u x 'may) (eqv? m #\O)) (if passive (w "may" (and neg "not") "be" pp) (w "may" (and neg "not") head)))
                   ;; a deliberative question: Μὴ κρύψω ἐγώ "Shall I hide"
                   ((or (u x 'yn-question) (u x 'question))
                    (if passive (w "shall" (and neg "not") "be" pp) (w "shall" (and neg "not") head)))
                   (else (if passive (w (and neg "not") "be" pp) (w (and neg "do not") head))))))
      (else
       (cons #f
             (case (if (u x 'would) 'would tense)
               ;; ἄν + past indicative: "would have sent", "would be sending"
               ((would) (case tense
                          ((#\I) (cond (be? (neg-aux "would" "be")) (passive (neg-aux "would" "be being" pp))
                                       (else (neg-aux "would" "be" (english-ing head)))))
                          (else (if passive (neg-aux "would" "have been" pp) (neg-aux "would" "have" pp)))))
               ((#\P) (cond (be? (neg-aux (be-form 'present person number)))
                            (passive (neg-aux (be-form 'present person number) pp))
                            ((and (eqv? person #\3) (eqv? number #\S)) (simple (english-s3 head) "does"))
                            (else (simple head "do"))))
               ((#\I) (cond ((and be? (lemma-in? x "εἰμί")) (neg-aux (be-form 'past person number)))
                            ;; a state, "be able", "be seated": the imperfect is "was able",
                            ;; "were not able" (not "were not being able")
                            (be? (neg-aux (be-form 'past person number)))
                            (passive (neg-aux (be-form 'past person number) "being" pp))
                            (else (neg-aux (be-form 'past person number) (english-ing head)))))
               ((#\F) (cond (be? (neg-aux "will" "be")) (passive (neg-aux "will" "be" pp)) (else (neg-aux "will" head))))
               ((#\R) (let ((aux (if (and (eqv? person #\3) (eqv? number #\S)) "has" "have")))
                        (if passive (neg-aux aux "been" pp) (neg-aux aux pp))))
               ((#\L) (if passive (neg-aux "had" "been" pp) (neg-aux "had" pp)))
               (else (cond (be? (neg-aux (be-form 'past person number)))
                           (passive (neg-aux (be-form 'past person number) pp))
                           (else (simple past "did"))))))))))

(define (pronoun-english x)
  (let* ((t (tp x)) (person (tag-field t 'person)) (c (tag-field t 'case))
         (n (tag-field t 'number)) (g (tag-field t 'gender))
         ;; an infinitive's subject is a possessive: "after his begetting"
         (poss (memq (u x 'role) '(possessive inf-subject))))
    (case (if (u x 'as-nominative) 'nominative person)
      ;; a genitive absolute's subject: καθημένου αὐτοῦ "he being seated"
      ((nominative)
       (case person
         ((#\1) (if (eqv? n #\P) "we" "I"))
         ((#\2) "you")
         (else (cond ((eqv? n #\P) "they")
                     ((eq? (u x 'ante) 'thing) "it")
                     ((eqv? g #\F) "she")
                     ((and (mn-ambiguous? x) (eq? (u x 'ante) 'person)) "he")
                     ((mn-ambiguous? x) "he/it")
                     ((eqv? g #\N) "it")
                     (else "he")))))
      ((#\1) (if (eqv? n #\P) (cond (poss "our") ((eqv? c #\N) "we") (else "us"))
                 (cond (poss "my") ((eqv? c #\N) "I") (else "me"))))
      ((#\2) (if poss "your" "you"))
      (else
       (if (eqv? n #\P)
           (cond (poss "their") ((eqv? c #\N) "they") (else "them"))
           ;; A thing is "it" whatever its Greek gender; a person by the
           ;; Greek gender; with no agreeing noun found, the masculine/neuter
           ;; αὐτοῦ, αὐτῷ stay open, "his/its", "him/it" (resolve-pronouns).
           (cond
            ((and (not (eqv? c #\N)) (eq? (u x 'ante) 'thing)) (if poss "its" "it"))
            ((and (mn-ambiguous? x) (eq? (u x 'ante) 'person)) (if poss "his" "him"))
            ((mn-ambiguous? x) (if poss "his/its" "him/it"))
            ((eqv? g #\F) (cond (poss "her") ((eqv? c #\N) "she") (else "her")))
            ((eqv? g #\N) (if poss "its" "it"))
            (else (cond (poss "his") ((eqv? c #\N) "he") (else "him")))))))))

(define (mn-ambiguous? x)
  "A third person singular genitive or dative masculine/neuter form."
  (and (memv (case-of x) '(#\G #\D)) (memv (gen-of x) '(#\M #\N)) (eqv? (num-of x) #\S)))

(define (reflexive-english x)
  (let* ((t (tp x)) (person (tag-field t 'person)) (n (tag-field t 'number)) (g (tag-field t 'gender)))
    (case person
      ((#\1) (if (eqv? n #\P) "ourselves" "myself"))
      ((#\2) (if (eqv? n #\P) "yourselves" "yourself"))
      (else (cond ((eqv? n #\P) "themselves")
                  ((eq? (u x 'ante) 'thing) "itself")
                  ((and (mn-ambiguous? x) (eq? (u x 'ante) 'person)) "himself")
                  ((mn-ambiguous? x) "himself/itself")
                  ((eqv? g #\F) "herself")
                  ((eqv? g #\N) "itself")
                  (else "himself"))))))

(define (noun-english sense number)
  (let ((g (gloss1 sense)))
    (if (and (eqv? number #\P) (not (string-null? g)))
        (let* ((pl (or (field1 sense 'plural) (english-plural g)))
               (listed (find (lambda (s) (string-ci=? s pl)) (gloss-list sense))))
          (or listed pl))
        g)))

(define (unit-english env x)
  "The English of unit X itself, without helper or subject pronoun; for a
third person imperative (let . rest)."
  (let ((sense (unit-sense env x)))
    (cond
     ((u x 'fixed) (u x 'fixed))
     ((not sense) (string-append "{" (u x 'greek) "}"))
     ((is? x "V") (verb-english env x))
     ((is? x "T")
      (case (u x 'role)
        ((the) "the")
        ((the-one) (string-append "the [" (if (eqv? (gen-of x) #\N) "thing" "one") (if (eqv? (num-of x) #\P) "s" "") "]"))
        ((pronoun) (cond ((eqv? (num-of x) #\P) "they") ((eqv? (gen-of x) #\F) "she") ((eqv? (gen-of x) #\N) "it") (else "he")))
        (else "")))
     ((member (gloss1 sense) '("")) "")
     ((is? x "N") (let ((e (noun-english sense (num-of x))))
                    (if (u x 'human-lord) (string-downcase e) e)))
     ((is? x "P") (if (lemma-in? x "αὐτός" "ἐγώ" "σύ") (pronoun-english x) (gloss1 sense)))
     ((is? x "F") (reflexive-english x))
     ((is? x "D") (if (eqv? (num-of x) #\P) (let ((g (gloss-list sense))) (if (> (length g) 1) (second g) (car g))) (gloss1 sense)))
     ;; ὅς: "who"/"whom" when its nearest agreeing noun is a person (the
     ;; concordance's (person) or a name), else "which" (rule 16a).
     ((is? x "R")
      (if (and (lemma-in? x "ὅς") (u x 'person-ante))
          (if (eqv? (case-of x) #\N) "who" "whom")
          (gloss1 sense)))
     ((is? x "I") (if (and (lemma-in? x "τίς") (eq? (car sense) 'who)) (if (eqv? (gen-of x) #\N) "what" "who") (gloss1 sense)))
     ((is? x "A")
      (case (tag-field (tp x) 'degree)
        ;; (a gloss already superlative, "most high", is not doubled)
        ((#\S) (if (string-prefix? "most " (gloss1 sense)) (gloss1 sense) (string-append "most " (gloss1 sense))))
        ((#\C) (cond ((field1 sense 'comparative) => identity)
                     ((string-suffix? "er" (gloss1 sense)) (gloss1 sense))
                     (else (string-append "more " (gloss1 sense)))))
        (else (gloss1 sense))))
     (else (gloss1 sense)))))

(define (punct-english p)
  (string-map (lambda (c) (case c ((#\·) #\;) ((#\;) #\?) (else c))) p))

(define (capitalize-text s)
  (let ((i (string-index s char-alphabetic?)))
    (if i (string-append (substring s 0 i) (string (char-upcase (string-ref s i))) (substring s (+ i 1))) s)))

(define (only-first-speech . piece-lists)
  "A unit's pieces in order; only the first opens direct speech."
  (match (concatenate piece-lists)
    (() '())
    ((p . rest) (cons p (map (lambda (q) (u+ q 'speech #f)) rest)))))

(define (span->segments env span span-cap?)
  "SPAN (units in English order) as segments (text ref ...): ref (n sense
lemma) or (cont n)."
  (let* ((span (map (lambda (x)
                      ;; An article's role is its concordance sense (ὁ: the,
                      ;; unrendered, attributive, infinitive, absorbed).
                      (if (and (is? x "T") (lemma-in? x "ὁ") (u x 'role) (not (u x 'sense)))
                          (u+ x 'refs (map (match-lambda ((n _ l) (list n (if (eq? (u x 'role) 'the-one) 'the (u x 'role)) l)) (r r))
                                           (u x 'refs)))
                          x))
                    span))
         ;; Direct speech opens at the first English word of its clause, also
         ;; when the opening Greek word moved (λέγουσα Ἐξανέστησεν γάρ μοι ὁ θεός:
         ;; "saying, For God raised up").
         (span (fold (lambda (s span)
                       (let ((k (index-where span (lambda (y) (and (u y 'idx) (>= (u y 'idx) (u s 'idx)))))))
                         (if (and k (not (eqv? (u (list-ref span k) 'idx) (u s 'idx))))
                             (map (lambda (y j) (cond ((= j k) (u+ y 'speech #t 'cap #t))
                                                      ((eqv? (u y 'idx) (u s 'idx)) (u+ y 'speech #f))
                                                      (else y)))
                                  span (iota (length span)))
                             span)))
                     span
                     (filter (lambda (x) (u x 'speech)) span)))
         (words (remove (lambda (x) (or (u x 'let-marker) (u x 'tail-piece) (u x 'supplied-piece))) span))
         (greek-order (sort words (lambda (a b) (< (u a 'idx) (u b 'idx)))))
         (first-greek (car greek-order))
         (punct (punct-english (u (last greek-order) 'post)))
         (pieces
          (append-map
           (lambda (x k)
             ;; μὴ λαλείτω ... ὁ θεός: "let not God speak" (KJV order keeps
             ;; the μή in the segment that owns it)
             (let* ((e (cond ((u x 'question-aux) (car (split-first (cdr (unit-english env (u x 'verb))))))
                             ((u x 'let-marker) (if (u x 'neg) "let not" "let"))
                             ((u x 'tail-piece) (u x 'text))
                             ((u x 'supplied-piece) (u x 'text))
                             (else (unit-english env x))))
                    ;; an infinitive's noun subject: "after Lot's being separated"
                    (e (if (and (u x 'poss-s) (string? e) (not (string-null? e))) (string-append e "'s") e))
                    (speech? (and (u x 'speech) (u x 'cap) (not (eqv? (u x 'idx) (u first-greek 'idx))) (> k 0)))
                    (compose (lambda (core subj)
                               (string-join (filter (lambda (s) (and s (not (string-null? s))))
                                                    (list (u x 'pre) (u x 'helper)
                                                          (and (not (string-null? (u x 'helper))) (u x 'before))
                                                          subj core))
                                            " ")))
                    (mk (lambda (text refs) `((text . ,(if (and (u x 'keep-cap) (pair? refs)) (capitalize-text text) text))
                                              (refs . ,refs) (speech . ,speech?)
                                              (prefix . ,(and (is? x "T") (pair? refs)))))))
               (only-first-speech
                ;; a supplied word before the word goes after its case helper:
                ;; "of [the] Lord", "altar to [the] Lord" (one segment)
                (if (and (u x 'before) (string-null? (u x 'helper))) (list (mk (u x 'before) '())) '())
                (cond
                 ;; an (english ...) override of a pronoun keeps its case helper
                 ;; (αὐτῷ (english "him/it"): "to him/it"); on other words the
                 ;; override is the whole English, helper included
                 ((u x 'english)
                  (let* ((h (if (and (is? x "P" "F")
                                     (member (u x 'english) '("him/it" "his/its" "himself/itself" "him" "her" "it" "them" "his" "its" "he/it")))
                                (u x 'helper) ""))
                         (t (u x 'english))
                         (b (and (not (string-null? (u x 'helper))) (u x 'before)))
                         (t (if b (string-append b " " t) t))
                         (t (if (or (string-null? h) (string-prefix? (string-append h " ") t) (string=? h t)) t (string-append h " " t))))
                    (list (mk t (u x 'refs)))))
                 ((u x 'tail-piece) (list (mk e (list (list 'cont (u x 'n))))))
                 ((u x 'supplied-piece) (list (mk e '())))
                 ((pair? e)
                  (match e
                    ((_ . rest) (=> next)
                     (if (u x 'let-rest)
                         (list (mk (if (u x 'question-rest) (cdr (split-first rest)) rest) (list (list 'cont (u x 'n)))))
                         (next)))
                    ((_ . rest) (=> next)
                     ;; ποῦ εἶ: "where are you" (auxiliary, subject, rest)
                     (if (u x 'question)
                         (let ((ar (split-first rest)))
                           (list (mk (compose (string-join (filter (lambda (s) (and s (not (string-null? s))))
                                                                   (list (car ar) (u x 'subj) (cdr ar)))
                                                           " ")
                                              #f)
                                     (u x 'refs))))
                         (next)))
                    (("let" . rest)
                     (list (mk (compose (string-join
                                         (remove string-null?
                                                 (list "let" (if (eqv? (num-of x) #\P) "them"
                                                                 (match (u x 'subj) ("he" "him") ("she" "her") ("he/she/it" "him/her/it") (#f "it") (s s)))
                                                       rest))
                                         " ")
                                        #f)
                               (u x 'refs))))
                    ((_ . rest) (list (mk (compose (if (u x 'hortatory) (string-append "let us " rest) rest)
                                                   (and (not (u x 'hortatory)) (not (u x 'nor)) (u x 'subj)))
                                          (u x 'refs))))))
                 (else (list (mk (compose e #f) (u x 'refs)))))
                (if (u x 'after) (list (mk (u x 'after) '())) '()))))
           span (iota (length span))))
         ;; Empty pieces (unrendered words) join the next piece, else the last;
         ;; an article's "the" (with its helper) joins its noun: "of the waters".
         (merged (let loop ((ps pieces) (carry '()) (text "") (sp #f) (acc '()))
                   (match ps
                     (() (if (and (pair? carry) (pair? acc))
                             (reverse (cons (u+ (car acc) 'refs (append (u (car acc) 'refs) carry)
                                                'text (string-trim-both (string-append (u (car acc) 'text) " " text)))
                                            (cdr acc)))
                             (reverse acc)))
                     ((p . rest)
                      (cond ((string-null? (string-trim-both (u p 'text)))
                             (loop rest (append carry (u p 'refs)) text (or sp (u p 'speech)) acc))
                            ;; a supplied word ("[the]") passes the carried Greek on
                            ;; to the next word: ἐν τῷ ... "in [the] Lord's"
                            ((and (null? (u p 'refs)) (pair? carry) (pair? rest) (string-null? text) (string-prefix? "[" (u p 'text)))
                             (loop rest carry "" #f (cons (u+ p 'speech (or sp (u p 'speech))) acc)))
                            ((and (u p 'prefix) (pair? rest))
                             (loop rest (append carry (u p 'refs)) (string-trim-both (string-append text " " (u p 'text)))
                                   (or sp (u p 'speech)) acc))
                            (else
                             (loop rest '() "" #f
                                   (cons (u+ p 'refs (append carry (u p 'refs))
                                             'speech (or sp (u p 'speech))
                                             'text (string-trim-both (string-append text " " (u p 'text))))
                                         acc))))))))
         (n (length merged)))
    (map (lambda (p k)
           (let* ((text (u p 'text))
                  (text (if (or (and (= k 0) span-cap?) (u p 'speech)) (capitalize-text text) text))
                  (text (if (and (< (+ k 1) n) (u (list-ref merged (+ k 1)) 'speech)) (string-append text ",") text))
                  (text (if (= k (- n 1)) (string-append text punct) text)))
             (cons text (u p 'refs))))
         merged (iota n))))

(define (order-span env span)
  "One punctuation-delimited span of units in English order (the word order
rules of gsb/literal/README.md)."
  (invert-questions env
    (place-particles env
      (find-subjects env (participle-subjects env (move-verbal-subjects (np-internal-moves (merge-negation (move-postpositives span)))))))))

(define* (render-verse env ref words prev-full-stop? #:optional (prev-words '()))
  "Segments for one verse (WORDS: rows of read-greek-table), and whether it
ends a sentence. PREV-WORDS, the verse before, is where a pronoun may find
its antecedent. Pinned verses are the caller's business (env-pins)."
  (let ()
    (begin
        (let* ((units (analyze-verse env ref words prev-words))
               (spans (split-spans units))
               (segs (let loop ((spans spans) (cap? prev-full-stop?) (acc '()))
                       (if (null? spans)
                           acc
                           (let* ((span (car spans))
                                  (first-cap (u (car span) 'lower-cap))
                                  (ordered (order-span env span)))
                             (loop (cdr spans)
                                   (sentence-end? (u (last span) 'post))
                                   (append acc (span->segments env ordered (or cap? first-cap)))))))))
          (values segs (and (pair? words) (sentence-end? (word-post* (last words)))))))))

(define (explain-verse env ref words)
  "One line per Greek word: the reading chosen and the roles assigned, for
`gsb-literal.sh explain`."
  (map (lambda (x)
         (format #f "~a\t~a\t~a\t~a\t~a\t~a\t~a~a"
                 (u x 'n) (u x 'greek) (or (lemma x) "") (or (u x 'tag) "?")
                 (or (u x 'sense) "") (or (u x 'role) "") (u x 'helper)
                 (if (u x 'phrase) (format #f "\tphrase ~s" (u x 'fixed)) "")))
       (analyze-verse env ref words)))

(define (verse-units env ref words)
  (mark-clauses
   (mark-mh env
            (assign-verse-context env (mark-gerunds env (assign-helpers env (mark-genitive-absolutes env (assign-roles env (collapse-phrases env (base-units env ref words))))))))))

(define* (analyze-verse env ref words #:optional (prev-words '()))
  "The verse's units with readings, roles, helpers and context, in Greek
order; PREV-WORDS the verse before, for pronoun antecedents."
  (resolve-pronouns env (verse-units env ref words)
                    (if (null? prev-words) '() (verse-units env "" prev-words))))

(define (sentence-end? post)
  "Greek full stop or question mark (;) ends a sentence."
  (and (or (string-contains post ".") (string-contains post ";")) #t))

;;; ---------------------------------------------------------------------------
;;; Output
;;; ---------------------------------------------------------------------------

(define (segments->sexp env segs table-lemmas)
  "Segments in translation-file form: refs as N, (N sense) or (N sense
\"lemma\"), the lemma written only when it differs from the table's."
  (map (lambda (s)
         (cons (car s)
               (map (match-lambda
                      (('cont n) (list 'cont n))
                      ((n sense lem)
                       (let* ((default (let ((ss (and lem (hash-ref (env-senses env) lem)))) (and (pair? ss) (caar ss))))
                              (sense (or sense default))
                              (table (hash-ref table-lemmas n "")))
                         (cond ((and (equal? lem table) (or (not sense) (eq? sense default))) n)
                               ((equal? lem table) (list n sense))
                               ((not sense) (list n 'unknown lem))
                               (else (list n sense lem))))))
                    (cdr s))))
       segs))

(define (write-chapter port header verses)
  "VERSES: (number . segments-sexp)."
  (display header port)
  (for-each (match-lambda
              ((num . segs)
               (format port "~%(verse ~s~%  (status draft)~%  (literal" num)
               (for-each (lambda (s) (display "\n    " port) (write s port)) segs)
               (display "))\n" port)))
            verses))

;;; ---------------------------------------------------------------------------
;;; Checks on the data behind a verse
;;; ---------------------------------------------------------------------------

(define (verse-warnings env ref words)
  "Warnings (kind ref#n greek detail) that do not fail the check: a reading
borrowed from the New Testament where it was ambiguous in lemma or part of
speech, and a verse more than half of whose words are overridden."
  (let* ((override? (lambda (w) (hash-ref (env-overrides env) (format #f "~a#~a" ref (word-n w)))))
         (borrowed
          (filter-map
           (lambda (w)
             (let* ((key (form-key (word-text* w)))
                    (nt (and (not (hash-ref (env-forms env) key)) (not (override? w)) (hash-ref (env-nt env) key))))
               (and nt (> (length nt) 1)
                    (> (length (delete-duplicates
                                (map (lambda (r) (cons (first r) (tag-field (parse-tag (second r)) 'pos))) nt)))
                       1)
                    (list 'ambiguous-nt-reading (format #f "~a#~a" ref (word-n w)) (word-text* w)
                          (string-join (map (lambda (r) (string-append (first r) " " (second r))) nt) " | ")))))
           words))
         (n-over (count override? words))
         ;; καὶ ὕπνωσεν after ἐπέβαλεν ὁ θεὸς ἔκστασιν ἐπὶ τὸν Ἀδάμ: a verb with
         ;; no pronoun after a clause that names another person in a
         ;; non-nominative case may read as continuing the wrong subject.
         (units (analyze-verse env ref words))
         (kai-after-person
          (let loop ((us units) (since-verb '()) (seen-verb? #f) (acc '()))
            (match us
              (() (reverse acc))
              ((x . rest)
               (cond
                ((and (finite? x) (u x 'kai-joined) (not (u x 'subject)) seen-verb?
                      (any (lambda (y) (and (person-noun? env y) (case-of y) (not (eqv? (case-of y) #\N)))) since-verb))
                 (loop rest '() #t
                       (cons (list 'kai-joined-after-another-person (format #f "~a#~a" ref (u x 'n)) (u x 'greek)
                                   "no pronoun, as the Greek has none; if it reads as the wrong subject, override (subject \"he/she/it\")")
                             acc)))
                ((finite? x) (loop rest '() #t acc))
                (else (loop rest (cons x since-verb) seen-verb? acc)))))))
         ;; A verb whose subject the rules could not tell apart (an
         ;; indeclinable name with an apposition in another case, a second
         ;; nominative): left in Greek order, to be read (gsb/literal/README.md).
         (unsure
          (filter-map (lambda (x)
                        (and (u x 'subject-unsure)
                             (list 'subject-unsure (format #f "~a#~a" ref (u x 'n)) (u x 'greek)
                                   "subject not certain: Greek order kept; check the verse states the right actor, else add an override")))
                      (append-map (lambda (span) (order-span env span)) (split-spans units)))))
    (append borrowed kai-after-person unsure
            ;; ἔλαβον with no cue for "I" or "they" (person-1s-3p!)
            (filter-map (lambda (x)
                          (and (u x 'person-unsure)
                               (list 'person-unsure (format #f "~a#~a" ref (u x 'n)) (u x 'greek)
                                     "first singular or third plural, nothing in the sentence decides: the first form row is used; check it, else (tag ...) override")))
                        units)
            ;; Κύριε opening speech, Κύριος opening a sentence: Swete's capital
            ;; may be the position's, not the divine name's (gsb/literal/README.md)
            (let loop ((us units) (prev #f) (acc '()))
              (match us
                (() (reverse acc))
                ((x . rest)
                 (loop rest x
                       (if (and (lemma-in? x "κύριος") (not (u x 'human-lord)) (not (u x 'phrase)) (not (u x 'english))
                                (or (eqv? (case-of x) #\V) (u x 'speech) (not prev) (strong-stop? (u prev 'post))))
                           (cons (list 'kyrios-capital-at-start (format #f "~a#~a" ref (u x 'n)) (u x 'greek)
                                       "a capital at a speech or sentence start: \"Lord\" (God) by Swete's capital; if a human is addressed or meant, override (english \"lord\")")
                                 acc)
                           acc)))))
            ;; ἐν τῷ τίκτειν αὐτήν: a transitive infinitive's one pronoun taken
            ;; as its subject by rule (mark-gerunds)
            (filter-map (lambda (x)
                          (and (u x 'inf-subject-by-rule)
                               (list 'inf-subject-by-rule (format #f "~a#~a" ref (u x 'n)) (u x 'greek)
                                     "taken as the infinitive's subject (\"her bearing\"); if it is the object, override (role: (english ...)) or pin")))
                        units)
            (if (and (pair? words) (> (* 2 n-over) (length words)))
                (list (list 'mostly-overrides ref "" (format #f "~a of ~a words overridden" n-over (length words))))
                '()))))

(define (verse-problems env ref words)
  "Problems with the analyses behind one verse, as (kind ref#n greek detail)."
  (let ((units (assign-roles env (collapse-phrases env (base-units env ref words)))))
    (append
     (append-map
      (lambda (x)
        (let ((at (format #f "~a#~a" ref (u x 'n))))
          (append
           (if (or (u x 'phrase) (u x 'tag)) '() (list (list 'unknown-form at (u x 'greek) (or (lemma x) ""))))
           (if (or (u x 'phrase) (not (lemma x)) (string-null? (lemma x)) (hash-ref (env-senses env) (lemma x))) '()
               (list (list 'lemma-not-in-glosses at (u x 'greek) (lemma x))))
           (let ((s (ref-sense* (car (u x 'refs)))))
             (if (and s (not (u x 'phrase)) (lemma x) (hash-ref (env-senses env) (lemma x)) (not (sense-of env (lemma x) s)))
                 (list (list 'no-such-sense at (u x 'greek) (format #f "~a ~a" (lemma x) s)))
                 '())))))
      units)
     (filter-map (lambda (a b)
                   (and (is? a "T") (memq (u a 'role) '(the)) (or (is? b "N" "A") (participle? b)) (case-of b) (not (agree? a b))
                        (list 'article-disagrees (format #f "~a#~a" ref (u a 'n)) (string-append (u a 'greek) " " (u b 'greek))
                              (format #f "~a / ~a" (u a 'tag) (u b 'tag)))))
                 units (if (null? units) '() (append (cdr units) (list #f)))))))

(define (normalize-for-compare text drop-supplied?)
  "TEXT lowercased with punctuation removed; brackets removed, and with
DROP-SUPPLIED? the bracketed words too."
  (let* ((t (if drop-supplied? (strip-supplied text) (string-delete (lambda (c) (memv c '(#\[ #\]))) text)))
         (t (string-map (lambda (c) (if (or (char-alphabetic? c) (memv c '(#\- #\'))) (char-downcase c) #\space)) t)))
    (string-join (string-tokenize t (char-set-union char-set:letter (char-set #\- #\'))) " ")))
