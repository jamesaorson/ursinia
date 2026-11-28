;; Copyright (C) 2026
;;
;; Builds a tiny GSB database (scripts lib gsb-db) from a two-verse gsb/ tree
;; in a temporary directory and checks a few queries against it: row counts,
;; the word_english view, full-text search and SQL quoting. Run by `make test`.

(use-modules (scripts lib gsb-db)
             (ice-9 format)
             (ice-9 textual-ports))

(fluid-set! %default-port-encoding "UTF-8")

(define failures 0)
(define (check what got want)
  (unless (equal? got want)
    (set! failures (+ failures 1))
    (format #t "FAIL ~a: got ~s, want ~s~%" what got want)))

(let ((problem (sqlite3-problem)))
  (when problem
    (format #t "FAIL gsb-db: ~a~%" problem)
    (exit 1)))

(define repo (getcwd))
(define tmp (mkdtemp (string-append (or (getenv "TMPDIR") "/tmp") "/gsb-db-test-XXXXXX")))

(define (put path text)
  (let mk ((d (dirname path)))
    (unless (file-exists? d) (mk (dirname d)) (mkdir d)))
  (call-with-output-file path (lambda (p) (display text p))))

(chdir tmp)
(put "gsb/schema.sql" (call-with-input-file (string-append repo "/gsb/schema.sql") get-string-all))
(put "gsb/books.tsv"
     "nn\tid\tenglish\tgreek\ttestament\tdeuterocanonical\trole\tsource\tnotes\tchapters\n01\tgen\tGenesis\tΓένεσις\tOT\tno\tmain\tswete\t\t50\n")
(put "gsb/greek/01-gen.tsv"
     (string-append
      "ref\tn\tpre\tword\tpost\tlemma\tstrong\tmorph\tflags\n"
      "gen.1.1\t1\t\tΕΝ\t\t\t\t\tcaps\n"
      "gen.1.1\t2\t\tἀρχῇ\t.\tἀρχή\tG746\t\t\n"
      "gen.1.2\t1\t\tἡ\t\tὁ\tG3588\t\t\n"
      "gen.1.2\t2\t\tγῆ\t.\tγῆ\tG1093\t\tlemma?,bracket\n"))
(put "gsb/lexicon/glosses/01-alpha.scm"
     "(lemma \"ἐν\" (sense in (gloss \"in\") (why \"w\")))
(lemma \"ἀρχή\" (sense beginning (gloss \"beginning\") (why \"God's 'first' word\")))\n")
(put "gsb/translation/01-gen/001.scm"
     "(note \"Chapter note.\")
(verse 1 (status draft)
  (literal (clause (\"In\" (1 in \"ἐν\")) (\"[the]\") (\"beginning.\" 2)))
  (readable \"In the beginning.\")
  (note 2 \"Word note.\"))\n")
(put "gsb/sources/swete/decisions.tsv"
     "book\tscan\tleaf\tline\treading_a\treading_b\treading_c_first\tchosen\tbasis\ngen\tscan\t33\t1\tEN\tἘΝ\tΕΝ\tΕΝ\timage\n")

(build-database! "out.sqlite")
(define (q sql) (sql-query "out.sqlite" sql))

(check "words" (q "SELECT count(*) FROM words") '(("4")))
(check "verses" (q "SELECT ref, greek FROM verses ORDER BY id") '(("gen.1.1" "ΕΝ ἀρχῇ.") ("gen.1.2" "ἡ γῆ.")))
(check "flags" (q "SELECT flags FROM words WHERE ref = 'gen.1.2' AND n = 2") '(("[\"lemma?\",\"bracket\"]")))
(check "word_english" (q "SELECT n, lemma, sense, english FROM word_english WHERE ref = 'gen.1.1' ORDER BY n")
       '(("1" "ἐν" "in" "In") ("2" "ἀρχή" "beginning" "beginning.")))
(check "segments" (q "SELECT seg, clause, text, supplied FROM translation_segments ORDER BY seg")
       '(("1" "0" "In" "0") ("2" "0" "[the]" "1") ("3" "0" "beginning." "0")))
(check "quoting" (q "SELECT why FROM glosses WHERE lemma = 'ἀρχή'") '(("God's 'first' word")))
(check "search" (q "SELECT v.ref FROM search JOIN verses v ON v.id = search.rowid WHERE search MATCH 'greek_plain: αρχη'")
       '(("gen.1.1")))
(check "search english" (q "SELECT count(*) FROM search WHERE search MATCH 'english: beginning'") '(("1")))
(check "notes" (q "SELECT ifnull(chapter,''), ifnull(ref,''), ifnull(n,''), markdown FROM notes ORDER BY id")
       '(("1" "" "" "Chapter note.") ("1" "gen.1.1" "2" "Word note.")))
(check "decisions" (q "SELECT leaf, chosen FROM transcription_decisions") '(("33" "ΕΝ")))

;; Same inputs, same bytes.
(build-database! "again.sqlite")
(check "deterministic"
       (string=? (call-with-input-file "out.sqlite" get-string-all #:encoding "ISO-8859-1")
                 (call-with-input-file "again.sqlite" get-string-all #:encoding "ISO-8859-1"))
       #t)

(chdir repo)
(system* "rm" "-rf" tmp)
(if (zero? failures)
    (format #t "gsb-db: all checks passed~%")
    (exit 1))
